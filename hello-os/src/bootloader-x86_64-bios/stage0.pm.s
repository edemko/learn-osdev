# This bootloader is actually a bootloader instead of just a bootsector executable.
# It loads a number of sectors from disk just after the bootsector, switches to 32-bit protected mode, then jumps to them.
# This file builds on the ideas of `stage0.rm.s`, so understand that one first.

# The interface exposed to the stage1 bootloader is much mostly the same as for the real-mode version.
# For ease-of-reference, we reproduce the entire interface here:
#
#  * Stage1 is assumed to be a flat 32-bit protected mode executable.
#  * The stage1 binary is loaded at address 0x8000.
#  * The second sector is loaded into addresses 0x7E00–0x7FFF (the second sector)
#    for a disk partition table (to be interpreted as stage 1 sees fit).
#  * The disk number the stage1 was loaded from is in `dl`, and
#  * the number of sectors loaded by the BIOS and stage0 bootloader combined is in `dh`.
#  * A simple GDT is set up and loaded with:
#      * a code segment at offset 0x08
#      * a data segment at offset 0x10
#      * TODO a stack segment at offset 0x18
#  * The segment selector registers are initialized accordingly:
#    the code segment for `cs`; the data segment for `ds`, `es`, `fs`, `gs`; and TODO the stack segment for `ss`.
#  * An empty stack is initialized at linear addresses 0x80000–0x8FFFF (`sp = 0x90000`).
#  * The flags register has interrupts enabled and direction forward, but other flags are undefined.
#    TODO check on any new flags that might need initialization
#  * BIOS/VGA video mode is initialized:
#      * video mode if 80x25 text mode
#      * cursor is disabled
#      * some text may already be on the screen
#  * The line number of the first blank line is in `edi`.
#  * Interrupts are disabled because
#  * the real mode IVT is preserved in-place.
#
# This leaves `eax`, `ebx`, `ecx`, the 16-high-order bits of `edx`, `esi, and `ebp` undefined,
# and probably also some other registers that I forgot.


.intel_syntax noprefix
.code16


.extern stage1.sectorCount # sectors to load for the disk partition table and stage1 program


# In order to enter protected mode, we'll need to initialize a data structure called the Global Descriptor Table (GDT).
# In essence, the meaning of the segment registers changes when we enter protected mode.
# Instead of being offsets added directly to a near pointer, they are indices into an in-memory table of segment descriptors.
# These descriptors then drive (in a fairly sophisticated way) how the given address is translated into a physical address.
.section .data
# However, the processor, which only really deals well with registers, actually only knows about this table through another, much smaller piece of data.
# There is a 6-byte GDT register (GDTR) which holds both the size and start location of the GDT.
# This register can only be loaded from memory, so we define it here.
# There doesn't seem to be a name for this location in memory (but let me know if you know of one).
# Since it is intended to be loaded into the GDT register (GDTR), I'll call it the "in-memory GDTR"
.balign 4 # align this on a four-byte boundary so the memory accesses to gdt.start will be aligned
.fill 2   # but the first member of this struct is two bytes and must be contiguous before gdt.start, so skip two bytes
# be aware that although GNU also offers `.align`, it is documented to act unexpectedly on some architectures
gdtr.memory:
  .hword gdt.end - gdt.start - 1 # size of the gdt in bytes minus one
                                 # The minus one is so that valid table sizes range up through 65536
                                 # instead of stopping short at 65535 (or actually 65532, since the entries are four bytes long).
  # It turns out that GNU as thinks that 16 bits is a half-word, which conflicts with intel's naming system ¯_(ツ)_/¯
  .int gdt.start # the linear address of the start of the table entries
  # In their infinite wisdom, the folks who wrote GNU as decided it would be fun to offer
  # directives to emit 1-, 2-, 8-, and 16-byte data, but if you want 4-byte data, oh… well…
  # You have to use directives whose meaning is documented to vary based on target; most hilarious!
  # Of course, I can't find the official docs that actually _say_ what size an `.int` is,
  # but other people say they use it, and it seems to work for me, so hold onto your hats, folks!
  # Why they didn't offer a `.dword` directive like normal humans is beyond me.

# Now that we have something to load into the GDTR, we need to initialize the GDT it points to.
# This is just a contiguous, linear table of segment descriptors.
# Each one defines the base and size of a segment, as well as many flags, most of which we won't explore in-depth.
.balign 8 # Since these entries are 8 bytes each, I'll 8-byte align them, though I expect 4-byte alignment as we already have is sufficient.
gdt.start:
  # The first entry in the GDT is mandated to be null.
  # This helps catch errors where segment registers were uninitialized.
  gdt.null: .quad 0
  # We'll also need at least one entry to load our segment registers with.
  # Since we can't make many assumptions about the stage 1 that we're loading (and it might replace our GDT this with its own anyway),
  # I'll use a variant of what Intel calls "Protected Flat Model" which has a separate stack segment.
  # In this mode, we set up three GDT entries:
  #   one for code and one for data, which both access the entire address space,
  #   and then another for the stack, which is much smaller boundaries.

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

  # FIXME I should define some stuff to help create these
  # like one-hots and macros to split the bits of base and offset apart

  # Great, now let's set one up.
  # First, the code segment, which will range over all memory and be read/execute.
  gdt.code:
  # We'll need to use offsets into the GDT entries, so let's pre-compute them here.
  .equ gdt.code.offset, gdt.code - gdt.start
    .hword 0xFFFF # limit bits 0-15
    .hword 0  # base bits 0-15
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
  .equ gdt.data.offset, gdt.data - gdt.start
    .hword 0xFFFF # limit bits 0-15
    .hword 0 # base bits 0-15
    .byte 0 # base bits 16-23
    .byte 0b10010010 # flag bits, as before, except:
                     # bit 3 (zero-indexed from the right) is clear specifying a data segment
                     # which means bit 1 set actually specifies read/write
    .byte 0b11001111 # as for the code segment
    .byte 0 # base bits 24-31
  gdt.stack:
  .equ gdt.stack.offset, gdt.stack - gdt.start
    # base 0x80000, limit 0xFFFF
    .hword 0xFFFF # limit bits 0-15
    .hword 0 # base bits 0-15
    .byte 0x8 # base bits 16-23
    .byte 0b10010010 # same flags as the data segment
    .byte 0b01000000 # as the data segment, but granularity cleared since we only need to access low memory
                     # and also limit bits 16-19 are zero
    .byte 0 # base bits 24-31
gdt.end:


.section .text
.global bootloader
bootloader:

  # Initialize processor state; see `donothing.s`
  cli
  jmp 0x0000:bootloader.canonPoint # canonicalize the `cs:ip` instruction pointer
  bootloader.canonPoint:
  mov ax, 0x8000 # setup stack
  mov ss, ax
  xor ax, ax
  mov sp, ax
  mov ds, ax # setup segment registers
  mov es, ax
  cld # setup flags
  sti

  # Initialize graphics state.
  call clearScreen


  # BIOS calls are not (easily) available in protected mode, so it'd be nice to
  # load everything we need from disk while we're still in real mode.
  # The other option is to write a disk driver, but it'd be too big to fit alongside the rest of this bootloader.

  # Display a message that we're loading the stage 1 bootloader.
  mov si, OFFSET msg.loading.stage1
  call rm_putstrln

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
  jc bootloader.rm_die         # carry flag set on error
  cmp al, [stage1.sectorCount] # al holds actual number of sectors read
  jnz bootloader.rm_die        # die if actual != expected
  # Plenty of code below clobbers `ax`, but `dx` is safe, so save the count of sectors loaded for later.
  mov dh, al



  # And finally, here's the _new_ part of the code: getting ready for and entering protected mode.
  # We'll disable interrupts, then load out GDTR, and flip on the protected mode bit.
  # Although we're now in protected mode, our segment registers are garbage, so
  # we need to act quickly to initialize our segment registers to point into the GDT
  # Finally, we'll enable the A20 line, because who doesn't love historic cruft?

  # Display a message that we're entering protected mode.
  mov si, OFFSET msg.enter.protmode
  call rm_putstrln

  # Disable interrupts, since the IVT is meant for 16-bit mode and will be garbage for 32-bit mode
  cli
  # Point the GDT register at the table we painstakingly set up above.
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
  # We'll need to remember to back and forth between .code16 and .code32 for different parts of this bootloader.
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
  # By using a 1MiB segment starting at 0x80000 (the "stack" entry in the GDT), we keep the same overflow protection as before.
  # However, this time the overflow protection will cause a fault rather than wrap-around (I like this better anyway: fail early and loudly).
  # Since we can't rely on wrap-around anymore, we'll need to alter where `esp` points to as well.
  mov ax, gdt.stack.offset
  mov ss, ax # TODO wouldn't it be cool to actually set up a segment specifically for the stack so we get some overflow protection?
  mov esp, 0x90000 # Remember, the first stack operation will decrement this, putting us in the 0x80000-0x8FFFF range before writing.
  # TODO I didn't set up a base pointer, this should probably be noted earlier, say in donothing.s

  # When a x86-family processor powers on, the A20 line (the twenty-first address bit) is disabled.
  # We'll need this on so that we can reference the odd-numbered megabytes of memory.
  # I've waited until now to do this because it is much easier to do with a flat protected mode than in segmented real mode,
  # and we don't need nearly 1MiB of memory to get here.
  # The BIOS might have already turned this on, so the first thing we do is check for this.
  # Do do this, we will compare two addresses in megabytes of different parity.
  # I'll choose the addresses 0x007DFE and 0x107DFE, since the former we know to be the bootsector's magic string.
  mov ax, 0xAA55    # the expected value in 0x7DFE (at the end of the bootsector)
  mov edi, 0x107DFE # the corresponding address in an odd-numbered MiB
  cmp ax, [edi]
  jnz a20.enabled # if they don't match, we know A20 is already enabled
  # Even if they do match, it might just be chance.
  # To make sure it's not already on, let's write to the location and check again.
  rorw [edi], 8 # rotate a word 8 bits, thereby swapping the bytes
  cmp ax, [edi]
  jz a20.enable   # this time, if they still match,
  mov [edi], ax   # we want to clean up the memory we altered, just in case this sector is written back
  jmp a20.enabled # but otherwise we know we're already enabled
  # If we've made it here, the A20 line is definitely not enabled.
  a20.enable:
    # QEMU (at least by default) does enable A20 before the bootsector is loaded, so I'm not sure how to test this yet.
    hlt # TODO I need to enable the A20 line
    # when I get to it, I should double-check and fail if it's still not enabled
  a20.enabled:


  #  Display a message that we are starting the stage-1 program.
  mov esi, OFFSET msg.enter.stage1
  mov edi, 2 # I happen to know exactly two lines will have been written by now
  call pm_putstrln

  # TODO it's probably a good idea to look for a magic number at the end of the stage 1 to ensure it's loaded correctly
  # heck, it could even be nifty to use a hash, but that sounds like more work than I really want to do
  # a checksum could work, though!

  # Enter the stage 1 code, which we've loaded earlier at address 0x8000.
  # TODO it's probably a good idea to drop a memory map diagram somewhere
  jmp 0x8000

  # If we couldn't jump to the stage 1 bootloader while in real mode, print error messages and stop.
  bootloader.rm_die:
  .code16
    mov si, OFFSET msg.loading.stage1.err
    call rm_putstrln
    jmp halt

# CALLCONV clearScreen
#| Clear the screen, set video mode to 80x25 text, and disable the cursor
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
  mov ah, 0x01 # BIOS function = set cursor shape
  mov ch, 0x10 # set cursor disabled bit
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
.code16
  # prologue
  push dx # save dx (this will be used to move the cursor)

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


# CALLCONV pm_putstrln
#| Write a NUL-terminated string directly to VGA-mapped memory.
#| It will only replace the line up to the end of the string; the rest of the line must be cleared separately if needed.
#| The text attributes also are left unchanged.
#| This function assumes VGA is already in text mode with 80 characters per line.
# protected mode
# esi: callee-save argument, pointer to start of a NUL-terminated string
# edi: argument, line number to print to
# edi: return value, next line number
# ax: clobbered
.func pm_putstrln
pm_putstrln:
.code32
  # prologue
  push edi
  # function body
  shl edi, 5                       # multiply edi by 32, and then
  lea edi, [4*edi + edi + 0xB8000] # and then five to give an overall multiply by 160
                                   # while also starting from the base of BGA memory
  jmp pm_putstrln.loop.entry
  pm_putstrln.loop.top:
    stosb   # write character data,
    inc edi # but leave attributes alone
  pm_putstrln.loop.entry:
    lodsb
    or al, al
    jnz pm_putstrln.loop.top
  pm_putstrln.loop.bottom:
  # epilogue
  pop edi
  inc edi
  ret
.endfunc


# CALLCONV halt
#| stop doing useful things
# real mode or protected mode
# no arguments
# does not return
.func halt
halt:
.code32 # this stretch of code compiles the same under .code16 and .code32
  cli      # mask out as many interrupts as possible
  hlt      # wait for an interrupt
  jmp halt # if an interrupt fires anyway, just loop while doing nothing
.endfunc



# I need to define the diagnostic strings I'll be printing.
.data
msg.loading.stage1: .asciz "Loading stage 1."
msg.loading.stage1.err: .asciz "Error loading stage 1."
msg.enter.protmode: .asciz "Entering protected mode."
msg.enter.stage1: .asciz "Entering stage 1."
