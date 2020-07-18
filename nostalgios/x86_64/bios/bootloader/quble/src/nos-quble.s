.include "qubleinfo.h"

.intel_syntax noprefix

.section .text
.code16


.global quble.load
.func quble.load
quble.load:
  # Use BIOS to load the stage 1 bootloader a disk.
  mov ah, 0x02                  # BIOS function = read sectors
  mov dl, [quble.diskno]        # disk
  mov cx, [quble.bootchain + 0] # sector (cl) & cylinder (ch)
  mov al, [quble.bootchain + 2] # number of sectors (less one)
  mov dh, [quble.bootchain + 3] # head
  cmp al, 64     # check requested sector count not too big
  ja load.err
  inc al         # adjust requested sector count
  push ax        # and save it for later
  mov bx, 0x07E0                # destination pointer is `es:bx`; here 0x07E0:0x0000
  mov es, bx
  xor bx, bx
  int 0x13                      # call BIOS disk function
  pop bx         # restore requested sector count into bl
  
  # Check for errors
  jc load.err # BIOS sets carry flag set on error
  cmp al, bl   # BIOS loads al with actual number of sectors read
  jnz load.err # error if actual != requested
  
  load.ok:
  # Prepare return values
  xor bh, bh # move loaded sector count from bl to bx
  mov di, bx # and ultimately do di
  shl di, 9      # multiply sectors by 512 to get bytes loaded
  add di, 0x7E00 # add on the base address
  xor ax, ax # clears carry flag
  ret

  load.err:
  stc
  ret
.endfunc

.global quble.initVideo
.func quble.initVideo
quble.initVideo:
  # set mode/clear screen
  mov ah, 0x00 # BIOS function = set video mode
  mov al, 0x03 # video mode argument = 80x25x16color text mode
  int 0x10     # call BIOS video function

  # set cursor position
  mov ah, 0x02 # BIOS function = set cursor
  xor bx, bx   # page number = 0
  xor dx, dx   # column = 0, row = 0
  int 0x10     # call BIOS video function

  ret
.endfunc

.global quble.message
.func quble.message
quble.message:
  # print the string from `si` at current position
  mov ah, 0x0E # Set function code to print a character
  jmp message.loop.entry
  message.loop.top:
    int 0x10 # call BIOS video function
  message.loop.entry:
    lodsb # auto-increment load the next character into the argument for the BIOS print-character call
    or al, al            # Check if this character is NUL;
    jnz message.loop.top # exit if so, but print and continue if not.
  message.loop.exit:

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

  ret
.endfunc



.global quble.halt
.func quble.halt
quble.halt:
  cli # mask out as many interrupts as possible
  hlt # wait for an interrupt
  jmp quble.halt # if an interrupt fires anyway, just loop while doing nothing
.endfunc
