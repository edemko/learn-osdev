# This bootloader does a little more than nothing: it prints out its own machine code in hex and then stops doing things.
# This file builds on the ideas of `hello-bios.s`, so understand that one first.
# It's jsut-for-fun so the documentation is not (TODO yet) up-to=par.


.intel_syntax noprefix

.section .text
.code16

.global bootloader
bootloader:

  # Clear the screen by setting the video mode.
  mov ah, 0x00 # BIOS function = set video mode
  mov al, 0x03 # video mode argument = 80x25 text mode
  int 0x10     # call BIOS function

  # Use a function to dump hex to the screen.
  mov si, OFFSET bootloader # pass the address of the memory we want to dump (start of the bootloader)
  mov cx, OFFSET bootloader.end # address where we want to stop dumping (end of the bootloader)
  sub cx, si                    # pass the number of bytes between the start and end addresses
  call dumphex

  # That's all we want this bootloader to do, so we halt.
  jmp halt


# CALLCONV dumphex
#| Use BIOS calls to print bytes in hexadecimal format.
# si: callee-save argument, pointer to start of a NUL-terminated string
# cx: callee-save argument, number of bytes to print
# ax: clobbered
.func dumphex
dumphex:
  mov ah, 0x0E # Set function code to print a character
  jmp putstr.loop.entry
  putstr.loop.top:
    # Load the next byte and increment pointer
    mov bl, [si]
    inc si
    # Decrement count of bytes remaining to print
    dec cx
    # Convert the byte into two nybbles.
    mov bh, bl   # get a second copy of the byte
    and bl, 0x0F # mask the low four bits in one copy for the low nybble
    shr bh, 4   # shift the other copy down four bits for the high nybble
    # Convert and print the high nybble
    mov al, bh
    call nybble2ascii
    int 0x10
    # Convert and print the low nybble
    mov al, bl
    call nybble2ascii
    int 0x10
    # Print a space, for "clarity"
    mov al, ' '
    int 0x10
  putstr.loop.entry:
    or cx, cx           # if the remaining count is not zero,
    jnz putstr.loop.top # continue the loop
  putstr.loop.bottom:
  ret
.endfunc


# CALCONV nybble2ascii
#| convert a nybble to its (uppercase) hexadecimal ASCII character
# al: argument, nybble to convert
# al: return, converted character
.func nybble2ascii
nybble2ascii:
  cmp al, 9
  ja nybble2ascii.big
    add al, '0'
    ret
  nybble2ascii.big:
    add al, 'A' - 10
    ret
.endfunc

# CALLCONV halt
#| stop doing useful things
# no arguments
# does not return
.func halt
halt:
  cli
  hlt
  jmp halt
.endfunc

# This label is here merely to mark the end of the bootloader code.
# This is used to find out how many bytes should be printed.
bootloader.end:
