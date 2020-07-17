# This bootloader is actually a bootloader instead of just a bootsector executable.
# It loads a number of sectors from disk just after the bootsector, then jumps to them.
# This file builds on the ideas of `hello.s`, so understand that one first.
# I'm using the deprecated BIOS calls to do this, just so I have a retrocomputing example.
# There are other approaches: see TODO.

# The overall architecture is called a two-stage bootloader.
# The bootsector is "stage zero", whose only purpose is to load a larger bootloader.
# This larger bootloader is called "stage one", and should have enough space for a filesystem driver.
# This should allow it to search for, load, and pass control to a kernel file.
# However, this stage zero doesn't assume the purpose of the stage 1, so it can be reused for multiple stage 1 bootloaders.

# The interface exposed to the stage 1 bootloader is as follows:
#
#  * Stage 1 is assumed to be a flat real mode executable.
#  * The stage 1 binary is loaded at linear address 0x08000.
#    FIXME I'd like this to be accessed with `cs:ip = 0x0800:0x0000`, but I'm having issues getting this to work at least under qemu.
#    For now, I'll just put up with only having a limited space to work in, but 65 sectors will have to do for now.
#  * The second sector is loaded into addresses 0x7E00–0x7FFF (the second sector) for a disk partition table.
#  * The disk number the stage 1 was loaded from is in `dl`, and
#  * the number of sectors loaded by the BIOS and stage 0 bootloader combined is in `dh`.
#  * The `ds`, `es` segment registers are zeroed, but
#  * the values in general-purpose registers are undefined.
#  * An empty stack is initialized at `ss:sp = 0x8000:0x0000`.
#  * The flags register has interrupts enabled and direction forward, but other flags are undefined.
#  * BIOS video mode is text mode (size technically undefined, but 80x25 if supported (and it probably is)), but
#  * some text may already be on screen, and the cursor is disabled.
#  * TODO document vis-a-vis the disk partition table


.intel_syntax noprefix
.code16


# An `.extern` directive declares a symbol as defined in another file.
# This one I intend to define in `stage0_sectorCount.o`.
# However, that object file is generated in a special way.
# See `do/hello-os/build/bootloader-x86_64-bios/stage0_sectorCount.o.do`.
# The symbol itself should hold a single byte that says how large the stage 1 bootloader is in sectors.
.extern stage1.sectorCount


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

  # Display a message that we're doing work
  mov si, OFFSET msg.enter.stage0
  call putstrln

  # We face a decision as to where to place the stage 1 bootloader in memory.
  # Just as when we were deciding on a location for the stack back in `donothing.s`,
  # there are a number of free locations (though now obvs we need to also avoid the stack.
  # I've selected linear address 0x07E00 to begin loading the disk partition table and stage1.
  # This is just after where this stage 0 is loaded.
  # This gives us up through address 0x7FFFF to play with for stage one,
  # which comes out to 0x78200 bytes, or 480.5 KiB, or 961 sectors.
  # In reality, we'll only be able to load up to 255 sectors (127.5KiB) with a single BIOS call,
  # which is fine, since we probably want to leave plenty of space for memory allocation by the stage1 bootloader.

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
  jc bootloader.die            # carry flag set on error
  cmp al, [stage1.sectorCount] # al holds actual number of sectors read
  jnz bootloader.die           # die if actual != expected

  # TODO it's probably a good idea to look for a magic number at the end of the stage 1 to ensure it's loaded correctly
  # heck, it could even be nifty to use a hash, but that sounds like more work than I really want to do

  # Display a message that the work is done
  mov dh, al # putstrln clobbers `ax`, so save the count of sectors loaded for later
  mov si, OFFSET msg.loaded.stage1
  call putstrln

  # Prepare environment for the stage-1 bootloader and jump to it.
  inc dh # dh = number of sectors in the stage 0 and stage 1 bootloaders combined
  # mov dl, dl # dl is already the disk number we're booting from
  # xor sp, sp # the stack should already be empty
  xor ax, ax # zero `es` register
  mov es, ax
  # Display a message that we are entering the next phase of booting
  mov si, OFFSET msg.enter.stage1
  call putstrln
  # jmp 0x0800:0 # long-jump to the start of the stage 1 bootloader # FIXME but I can't seem to get this to work on qemu, though the instruction encoding looks right ┻━┻ ︵ヽ(`Д´)ﾉ︵ ┻━┻
  jmp 0:0x8000 # so just jump to the correct linear location, leaving `cs = 0`

  # If we couldn't jump to the stage 1 bootloader, print error messages and stop.
  bootloader.die:
    # TODO it'd be nice to say why we died
    mov si, OFFSET msg.loading.stage1.err
    call putstrln
    mov si, OFFSET msg.die
    call putstrln
    jmp halt


# CALLCONV clearScreen
#| Clear the screen, set video mode to 80x25 text, and disable the cursor
# ax: clobbered
# bx: clobbered
# ch: clobbered
.func clearScreen
clearScreen:
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


# CALLCONV putstrln
#| Use BIOS calls to print a message (NUL-terminated, ASCII) onto the screen from the current cursor position.
#| Then move the cursor to the next line.
# si: callee-save argument, pointer to start of a NUL-terminated string
# ax: clobbered
# bx: clobbered
.func putstrln
putstrln:
  # prologue
  push dx # save dx (this will be used to move the cursor)

  # function body
  mov ah, 0x0E # Set function code to print a character
  # It's a common optimization to put the loop condition at the end but jump to the end to enter the loop.
  # This way there's only one unconditional jump no matter how many times through the loop you go.
  jmp putstrln.loop.entry
  putstrln.loop.top:
    int 0x10 # Call the BIOS through interrupt.
  putstrln.loop.entry:
    lodsb # Auto-increment load the next character as the argument to the BIOS print-character call
    or al, al             # Check if this character is NUL;
    jnz putstrln.loop.top # exit if so, but print and continue if not.
  putstrln.loop.exit:

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


# CALLCONV halt
#| stop doing useful things
# no arguments
# does not return
.func halt
halt:
  cli      # mask out as many interrupts as possible
  hlt      # wait for an interrupt
  jmp halt # if an interrupt fires anyway, just loop while doing nothing
.endfunc


# I need to define the diagnostic strings I'll be printing.
.data
msg.enter.stage0: .asciz "Entered stage 0 bootloader."
msg.enter.stage1: .asciz "Entering stage 1 bootloader..."
msg.loaded.stage1: .asciz "Loaded stage 1 bootloader."
msg.loading.stage1.err: .asciz "Problem loading stage 1 bootloader."
msg.die: .asciz "Goodbyte, cruel world!"
