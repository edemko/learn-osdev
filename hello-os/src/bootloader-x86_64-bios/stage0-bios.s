.intel_syntax noprefix
.code16

# TODO document me


.data
msg.loading.stage1: .asciz "Loading stage 1 bootloader."
msg.loaded.stage1: .asciz "Loaded stage 1 bootloader."
msg.loading.stage1.err: .asciz "Problem loading stage 1 bootloader."
msg.die: .asciz "Goodbyte, cruel world!"

.extern stage1.sectorCount
# stage1.sectorCount: .byte 1

.section .text
.global bootloader
bootloader:

  # Initialize processor state; see `donothing-bios.s`
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

  # Disaply a message that we're doing work
  mov si, OFFSET msg.loading.stage1
  call putstrln

  # Use BIOS function to load sectors from a disk.
  mov ah, 0x02 # BIOS function = read sectors
  # mov dl, dl # dl still has the disk number this bootloader was retrieve from
  mov ch, 0 # cylinder = 0
  mov dh, 0 # head = 0
  mov cl, 2 # sector = 2 (these are one-indexed, it seems (ノಠ益ಠ)ノ彡┻━┻ )
  mov al, [stage1.sectorCount] # count of sectors to read
  mov bx, 0x8000 # destination pointer is `es:bx`; here 0x8000:0x0000
  mov es, bx
  xor bx, bx
  int 0x13 # call BIOS disk function
  jc bootloader.die # carry flag set on error
  cmp al, [stage1.sectorCount] # al holds actual number of sectors read
  jnz bootloader.die # die if actual != expected

  # Disaply a message that the work is done
  mov si, OFFSET msg.loaded.stage1
  call putstrln

  # TODO jump into the stage-1 bootloader
  jmp halt

  # print error messages and stop
  bootloader.die:
    mov si, OFFSET msg.loading.stage1.err
    call putstrln
    mov si, OFFSET msg.die
    call putstrln
    jmp halt


# CALLCONV clearScreen
#| Clear the screen and set video mode to 80x25 text
# ax: clobbered
# bx: clobbered
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
  push dx # save dx (this will be used to move the dursor)

  # function body
  mov ah, 0x0E # Set function code to print a character
  # It's a common optimization to put the loop condition at the end but jump to the end to enter the loop.
  # This way there's only one unconditional jump no matter how many times through the loop you go.
  jmp putstrln.loop.entry
  putstrln.loop.top:
    int 0x10 # Call the BIOS through interrupt.
  putstrln.loop.entry:
    mov al, [si] # Load the next character as the argument to the BIOS print-character call
    inc si       # Point at the next character.
    cmp al, 0    # Check if this character is NUL; exit if so, but print and continue if not
    jnz putstrln.loop.top
  putstrln.loop.bottom:

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
  cli            # mask out as many interrupts as possible
  hlt            # wait for an interrupt
  jmp bootloader # if an interrupt fires anyway, just loop while doing nothing
.endfunc
