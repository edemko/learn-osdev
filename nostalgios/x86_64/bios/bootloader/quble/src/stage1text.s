.include "stage1text.h"

.intel_syntax noprefix

.section .data
line: .int 0


.section .text

.equ VIDEO, 0xB8000

.balign 16
.global printLn16
.func printLn16
printLn16:
  .code16
  # prologue
  mov ax, es # save es
  push ax
  push cx # save cx

  # function body
  mov ax, VIDEO >> 4 # set up destination segment to start from 0xB8000
  mov es, ax

  mov edi, [line] # load the current line
  cmp di, 25
  jnz printLn16.noscroll # if at bottom of screen, scroll the screen up one line
    push ds # save the start of the string `ds:si`
    push si
                # clear dst segment `es` is already set-up
    xor di, di  # clear dst offset `di` is start of video memory
    mov ax, es  # clear src segment `ds` is the same as dst segment
    mov ds, ax
    mov si, 160 # clear src offset `si` starts at the second line (160 bytes/line)
    mov cx, 80 * 24 + 1 # setup amount of memory that needs to move (80 words/line * 24 lines) plus one (since `loop` pre-decrements)

    jmp printLn16.clear.entry
    printLn16.clear.top:
      lodsw # ax = ds[si++]
      stosw # es[di++] = ax
    printLn16.clear.entry:
      loop printLn16.clear.top # if (--cx == 0) break
    printLn16.clear.bottom:

    pop si # restore the start of the string `ds:si`
    pop ds
    mov edi, [line] # restore the current line
  jmp printLn16.endscroll
  printLn16.noscroll: # if not at bottom, increment current line number
    mov cx, di
    inc cx
    mov [line], cx
  printLn16.endscroll:

  shl di, 5              # multiply ax by 32, and then
  lea edi, [4*edi + edi] # another five to give an overall multiply by 160 (2 bytes/char * 80 chars/line)
  mov cx, di  # get pointer to end of line
  add cx, 160 # by adding a line's worth of bytes
  # print line
  jmp printLn16.loop.entry
  printLn16.loop.top:
    stosb  # write character data,
    inc di # but leave attributes alone
  printLn16.loop.entry:
    lodsb
    cmp di, cx # exit when we've hit the end of the line
    jae printLn16.loop.bottom
    or al, al # goto clearing mode when we find a null character
    jnz printLn16.loop.top
    # `al` is already a null character, which should? act like a space
  printLn16.loop.clear:
  # clear rest of the line
    cmp di, cx               # stop at end of line
    jz printLn16.loop.bottom
    stosb  # write a space
    inc di # leave attribute byte alone
    jmp printLn16.loop.clear
    # TODO count until column is up through 25
  printLn16.loop.bottom:

  # epilogue
  pop cx # restore cx
  pop ax     # restore es
  mov es, ax
  ret
.endfunc


.balign 16
.global printLn32
.func printLn32
printLn32:
  .code32
  # prologue
  push ecx # save ecx

  # function body
  mov edi, [line] # load the current line
  cmp edi, 25
  jnz printLn32.noscroll # if at bottom of screen, scroll the screen up one line
    push esi # save the start of the string `esi`
    mov edi, VIDEO       # clear dst offset `edi` is start of video memory
    mov esi, VIDEO + 160 # clear src offset `esi` starts at the second line (160 bytes/line)
    mov ecx, 40 * 24 + 1 # setup amount of memory that needs to move (40 quads/line * 24 lines) plus one (since `loop` pre-decrements)

    jmp printLn32.clear.entry
    printLn32.clear.top:
      lodsd # eax = *esi++
      stosd # *edi++ = eax
    printLn32.clear.entry:
      loop printLn32.clear.top # if (--cx == 0) break
    printLn32.clear.bottom:

    pop esi # restore the start of the string `esi`
    mov edi, [line] # restore the current line
  jmp printLn32.endscroll
  printLn32.noscroll: # if not at bottom, increment current line number
    mov ecx, edi
    inc ecx
    mov [line], ecx
  printLn32.endscroll:

  shl edi, 5                     # multiply ax by 32, and then
  lea edi, [4*edi + edi + VIDEO] # another five to give an overall multiply by 160 (2 bytes/char * 80 chars/line)
                                 # and offset to start of video memory
  mov ecx, edi # get pointer to end of line
  add ecx, 160 # by adding a line's worth of bytes
  # print line
  jmp printLn32.loop.entry
  printLn32.loop.top:
    stosb   # write character data,
    inc edi # but leave attributes alone
  printLn32.loop.entry:
    lodsb
    cmp edi, ecx # exit when we've hit the end of the line
    jae printLn32.loop.bottom
    or al, al # goto clearing mode when we find a null character
    jnz printLn32.loop.top
    # `al` is already a null character, which should? act like a space
  printLn32.loop.clear:
  # clear rest of the line
    cmp edi, ecx             # stop at end of line
    jz printLn32.loop.bottom
    stosb   # write a space
    inc edi # leave attribute byte alone
    jmp printLn32.loop.clear
    # TODO count until column is up through 25
  printLn32.loop.bottom:

  # epilogue
  pop ecx # restore ecx
  ret
.endfunc


.balign 16
.global printLn64
.func printLn64
printLn64:
  .code64
  # TODO
.endfunc
