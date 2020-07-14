# TODO check documentation

# This bootloader is actually a bootloader instead of just an MBR executable.
# It loads a number of sectors from disk just after the MBR, switches to 32-bit protected mode, then jumps to them.
# This file builds on the ideas of `stage0.rm.s`, so understand that one first.
# I'm using the deprecated BIOS calls to do this, just so I have a retrocomputing example.
# There are other approaches: see TODO.

# The interface exposed to the stage1 bootloader is much mostly the same as for the real-mode version.
# The differences are as follows:
#  * Execution begins in 32-bit protected mode.
# TODO probably set up cs, ds, es, fs, gs differently
#  * An empty stack is initialized at TODO (but probably linear address 0x8000-0x8FFF again).
#  * TODO check on any new flags that might need initialization
#  * BIOS/VGA video mode is text mode (size technically undefined, but 80x25 if supported (and it probably is)), but
#  * some text may already be on screen.
#  * TODO may need to store cursor position in a register (probly bx or ebx)
#  * Interrupts will be disabled, and theInterrupt Vector Table (IVT) will be uninitialized.

.intel_syntax noprefix
.code16


.extern stage1.sectorCount # sectors to load for the disk partition table and stage1 program


# In order to enter protected mode, we'll need to initialize a data structure called the Global Descriptor Table (GDT).
# In essence, the meaning of the segment registers changes when we enter protected mode.
# Instead of being offsets added directly to a near pointer, they are indices into an in-memory table of segment descriptors.
# These descriptors then drive (in a fairly sophisticated way) how the given address is translated into a physical address.
.section .data
# The question you might have is: how does the CPU know where this table is in memory?
# In fact, this table data structure start directly in the table of segment descriptors.
# Instead, there's a size+pointer also in memory which we will later point a special register at.
# There doesn't seem to be a name for this location in memory (but let me know if you know of one).
# Since it is intended to be loaded into the GDT register (GDTR), I'll call it the "in-memory GDTR"
.balign 4 # align this on a four-byte boundary so the memory accesses to gdt.start will be aligned
.fill 2 # but the first member of this struct is 2-bytes and must be contiguous before sdt.start, so skip two bytes
# be aware that although GNU also offers `.align`, it can act funny on some architectures
gdtr.memory:
  .word gdt.end - gdt.start - 1 # size of the gdt in bytes minus one
                                # The minus one is so that valid table sizes range up through 65536
                                # instead of stoping short at 65535 (or actually 65532, since the entries are four bytes long).
  .int gdt.start # the linear address of the start of the table entries
  # In their infinite wisdom, the folks who wrote GNU as decided it would be fun to offer
  # directives to emit 1-, 2-, 8-, and 16-byte data, but if you want 4-byte data, oh well…
  # You have to use directives whose meaning is documented to vary based on target; most hilarious!
  # Of course, I can't find the official docs that actually _say_ what size an `.int` is,
  # but other people say they use it, and it seems to work for me, so hold onto your hats, folks!
  # Why they didn't offer a `.dword` directive like normal humans is beyond me.

# TODO document me
.balign 8 # Since these entries are 8 bytes each, I'll 8-byte align them, though I expect 4-byte alignment as we already have is sufficient.
gdt.start:
  # The first entry in the GDT is mandated to be null.
  # This helps catch errors where segment registers were uninitialized.
  gdt.null: .quad 0
  # We'll also need at least one entry to load our segment registers with.
  # Since we can't make many assumptions about the stage1 that we're loading (and it might replace out GDT this with its own anyway),
  # I'll just use what Intel calls "Protected Flat Model".
  # In this mode, we set up two GDT entries: one for code and one for data, but they both can access the entire address space.

  # The format for these entries is quite scrambled, for historical compatibility reasons if I had to guess.
  # The underlying concept of these entries is quite simple, being a base, size, and a bunch of flags.
  # For completeness, here they are listed:
  #   * a 32-bit base address
  #   * a 20-bit segment limit (size of the segment, but see granularity flag below)
  #   * a priviledge level from 0-3
  #   * a type, which is one of the following:
  #       * read-only
  #       * read/write
  #       * execute-only
  #       * read/execute
  #   * many flags:
  #       * a granularity bit which, if set, multiplies the limit by 4K (thus allowing it to range up to 4GB)
  #       * flag specifying the segment has 16/32 bit code
  #       * a "descriptor" bit: zero for traps, but one for code and data
  #       * for code segments a bit for "conforming", but for data segments a bit for "expansion direction"
  #       * a flag whether the segment is in physical memory (as opposed to virtual)
  #       * an accessed bit (for use with virtual memory)

  # Great, now let's set one up.
  # First, the code segment, which will range over all memory and be read/execute.
  gdt.code:
    .word 0xFFFF # limit bits 0-15
    .word 0  # base bits 0-15
    .byte 0 # base bits 16-23
    .byte 0b10011010 # a bunch of flags, from left-to-right:
                     # one bit set for "present" (in physical memory)
                     # 2-bit privilege level = zero (most privileged)
                     # one bit set specifying a code/data segment (not traps)
                     # one bit set specifying code segment
                     # one bit set specifying "non-conforming" (less-privileged code can't execute it)
                     # one bit for read/execute
                     # one bit for not accessed
    .byte 0b11001111 # more flags, from left-to-right:
                     #   one bit to multiply limit by 4K so we can access all memory
                     #   one bit set to signify the segment will hold 32-bit code
                     #   one bit clear to say the segment will not hold 64-bit code
                     #   a spare bit that we leave clear
                     # and the last four bits for the limit bits 16-19
    .byte 0 # base bits 24-31
  # Since the code segment is not writable, we'll need another segment to unlock read/write memory for data.
  # More complex setups with multiple data segments are possible which can protect memory from buggy or malicious programs.
  # However, we will not be using them yet, since we're still just initializing the system with trusted code.
  gdt.data:
    .word 0xFFFF # limit bits 0-15
    .word 0 # base bits 0-15
    .byte 0 # base bits 16-23
    .byte 0b10010010 # flag bits, as before, except:
                     # bit 3 (zero-indexed from the right) is clear specifying a data segment
                     # which means bit 1 set actually specifies read/write
    .byte 0b11001111 # as for the code segment
    .byte 0 # base bits 24-31
gdt.end:
# We'll need to use offsets into the GDT entries, so let's pre-compute them here.
.equ gdt.code.offset, gdt.code - gdt.start
.equ gdt.data.offset, gdt.data - gdt.start


.section .text
.global bootloader
bootloader:

  # Initialize processor state; see `donothing.s`
  cli
  jmp 0x0000:bootloader.canonPoint # cannonicalize the `cs:ip` insruction pointer
  bootloader.canonPoint:
  mov ax, 0x8000 # setup stack
  mov ss, ax
  xor ax, ax
  mov sp, ax
  mov ds, ax # setup segment registers
  mov es, ax
  cld # setup flags
  sti

  call clearScreen

  # Display a message that we're loading from disk
  mov si, OFFSET msg.enter.stage0
  call rm_putstrln

  # BIOS calls are (easily) not available in protected mode, so it'd be nice to
  # load everything we need from disk while we're still in real mode.
  # The other option is to write a disk driver, but it might be too big to fit alongside the rest of this bootloader.

  # Use BIOS to load the stage 1 bootloader a disk.
  mov ah, 0x02                 # BIOS function = read sectors
  # mov dl, dl                 # dl still has the disk number this bootloader was retrieved from
  mov ch, 0                    # cylinder = 0
  mov dh, 0                    # head = 0
  mov cl, 2                    # sector = 2 (these are one-indexed, it seems (ノಠ益ಠ)ノ彡┻━┻ )
  mov al, [stage1.sectorCount] # count of sectors to read
  mov bx, 0x07E0               # destination pointer is `es:bx`; here 0x07E0:0x0000
  mov es, bx
  xor bx, bx
  int 0x13                     # call BIOS disk function
  jc bootloader.rm_die            # carry flag set on error
  cmp al, [stage1.sectorCount] # al holds actual number of sectors read
  jnz bootloader.rm_die           # die if actual != expected

  # TODO it's probably a good idea to look for a magic number at the end of the stage1 to ensure it's loaded correctly
  # heck, it could even be nifty to use a hash, but that sounds like more work than I really want to do

  # Display a message that the loading is done
  mov dh, al # rm_putstrln clobbers `ax`, so save the count of sectors loaded for later
  mov si, OFFSET msg.loaded.stage1
  call rm_putstrln

  # Display a message that we're entering protected mode.
  mov si, OFFSET msg.enter.protmode
  call rm_putstrln

  # And finally, here's the _new_ part of the code: getting ready for and entering protected mode.
  # Disable interrupts, since the IVT is meant for 16-bit mode and will be garbage for 32-bit mode
  cli
  # Point the GST register at the table we painstakingly set up above.
  lgdt [gdtr.memory]
  # The first bit of a special-purpose control register controls whether the processor is in real or protected mode.
  # We need to set it, but this requires manipulation in a general-purpose register.
  # Note that we are actually allowed to use 32-bit registers in real mode (at least on 32-bit processors!).
  mov eax, cr0
  or eax, 0x1 # set bit 0
  mov cr0, eax
  # We need to immediately load the `cs` register with the offset to our GST's code segment.
  jmp gdt.code.offset:protected.entry
  protected.entry:

  # We need to tell our assembler that we're in a 32-bit mode now.
  # We'll need to remember to back and forth between .code16 and .code32 for different parts of this bpotloader.
  # I'll put the appropriate directive at the start of every function, just so we're sure what's going on without looking around to far.
  .code32
  # Before we can access any data, we'll need to load our other segment registers.
  # There are also two new general-purpose segment registers for 32-bit code: `fs` and `gs`.
  mov ax, gdt.data.offset
  mov ds, ax
  mov es, ax
  mov fs, ax
  mov gs, ax
  # We'll also need to setup our stack again, since the previous `ss` is no longer valid.
  # Since we've moved to a flat memory model, the `sp` (now `esp`) has to be updated as well.
  # Since we can't rely on overflow anymore, we'll need to alter where `esp` points to as well.
  mov ss, ax # TODO wouldn't it be cool to actually set up a segment specifically for the stack so we get some overflow protection?
  mov esp, 0x90000 # Remember, the first stack operation will decrement this, putting us in the 0x80000-0x8FFFF range before writing.
  # TODO I didn't set up a base pointer, this should probably be noted earlier, say in donothing.s
  # FIXME don't I need to enable the A20 line?

  # TODO Display a message that we are starting the stage-1 program

  # Enter the stage1 code, which we've loaded earlier at address 0x8000.
  jmp 0x8000

  # If we couldn't jump to the stage1 bootloader while in real mode, print error messages and stop.
  bootloader.rm_die:
  .code16
    # TODO it'd be nice to say why we died
    mov si, OFFSET msg.loading.stage1.err
    call rm_putstrln
    mov si, OFFSET msg.die
    call rm_putstrln
    jmp rm_halt

  # TODO bootloader.pm_die

# CALLCONV clearScreen
#| Clear the screen and set video mode to 80x25 text
# real mode
# ax: clobbered
# bx: clobbered
.func clearScreen
clearScreen:
  .code16
  # prologue
  push dx
  # function body
  mov ah, 0x00 # BIOS function = set video mode
  mov al, 0x03 # video mode argument = 80x25 text mode
  int 0x10     # call BIOS video function
  mov ah, 0x02 # BIOS function = set cursor
  xor bx, bx   # page number = 0
  xor dx, dx   # column = 0, row = 0
  int 0x10     # call BIOS video function
  # epilogue
  pop dx
  ret
.endfunc


# CALLCONV rm_putstrln
#| Use BIOS calls to print a message (NUL-terminated, ASCII) onto the screen from the current cursor position.
#| Then move the cursor to the next line.
# real mode
# si: callee-save argument, pointer to start of a NUL-terminated string
# ax: clobbered
# bx: clobbered
.func rm_putstrln
rm_putstrln:
  # prologue
  push dx # save dx (this will be used to move the dursor)

  # function body
  mov ah, 0x0E # Set function code to print a character
  # It's a common optimization to put the loop condition at the end but jump to the end to enter the loop.
  # This way there's only one unconditional jump no matter how many times through the loop you go.
  jmp rm_putstrln.loop.entry
  rm_putstrln.loop.top:
    int 0x10 # Call the BIOS through interrupt.
  rm_putstrln.loop.entry:
    lodsb # Auto-increment load the next character as the argument to the BIOS print-character call
    or al, al             # Check if this character is NUL;
    jnz rm_putstrln.loop.top # exit if so, but print and continue if not.
  rm_putstrln.loop.bottom:

  # move cursor to next line
  # get the cursor position (assuming page zero)
  mov ah, 0x03 # BIOS function = get cursor
  xor bx, bx   # page number to query = 0
  int 0x10     # call BIOS video function
  # modify cursor position
  mov ah, 0x02 # BIOS function = set cursor
               # page number is still zero
  xor dl, dl   # column = 0
  inc dh       # row += 1
  int 0x10     # call BIOS video function

  # epilogue
  pop dx # restore dx
  ret
.endfunc

# TODO pm_putstrln


# CALLCONV rm_halt
#| stop doing useful things
# real mode
# no arguments
# does not return
.func rm_halt
rm_halt:
  cli            # mask out as many interrupts as possible
  hlt            # wait for an interrupt
  jmp bootloader # if an interrupt fires anyway, just loop while doing nothing
.endfunc


# I need to define the diagnostic strings I'll be printing.
.data
msg.enter.stage0: .asciz "Entered stage 0 bootloader."
msg.enter.protmode: .asciz "Entering protected mode..."
msg.enter.stage1: .asciz "Entering stage 1 bootloader..."
msg.loaded.stage1: .asciz "Loaded stage 1 bootloader."
msg.loading.stage1.err: .asciz "Problem loading stage 1 bootloader."
msg.die: .asciz "Goodbyte, cruel world!"
