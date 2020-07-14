# TODO document me


.intel_syntax noprefix

.section .data
hellostr:
  # define a NUL-terminated ASCII string
  # I'm not sure why GNU decided to leave off the second "i", but the "z" stands for "zero",
  # which is often how the ASCII "NUL" character is referred to in practice.
  # Rest assured, there is a real name for this character, though!
  .asciz "Hello, Stage One!"

.section .text
.code16

.global stage1
stage1:
  mov si, OFFSET hellostr # put the address of the string we want to print into `si`; in this case, it's at the `hellostr` label
  call putstr
jmp halt


# CALLCONV putstr
#| Use BIOS calls to print a message (NUL-terminated, ASCII) onto the screen from the current cursor position.
# si: callee-save argument, pointer to start of a NUL-terminated string
# ax: clobbered
.func putstr
putstr:
  # We're using the `si` register as the pointer to our message because `si` stands for "source index".
  # Besides, in real mode, many other registers (e.g. `dx`) can't be be dereferenced like `si` can be.
  # While I'm taking about is, `di` stands for "destination index", so I overall quite like `si` and `di`
  # for their self-documenting nature (as far as assembly even can be self-documenting).

  mov ah, 0x0E # Set function code to print a character
  # It's a common optimization to put the loop condition at the end but jump to the end to enter the loop.
  # This way there's only one unconditional jump no matter how many times through the loop you go.
  jmp putstr.loop.entry
  putstr.loop.top:
    int 0x10 # Call the BIOS through interrupt.
  putstr.loop.entry:
    lodsb # load the next character from `[si]` as the argument to the BIOS print-character call, and increment `si`
    # This is fewer bytes and fewer instructions than the naive way:
    #   mov al, [si] # Load the next character as the argument to the BIOS print-character call
    #   inc si       # Point at the next character.
    # But it does rely on the direction flag being forwards (which I know I set up early and don't change),
    # and it takes advantage of the nice coincidence that `lods` instructions target `a`-series registers which happens to be the register the BIOS needs its argument in.
    or al, al           # Check if this character is NUL;
    jnz putstr.loop.top # exit if so, but print and continue if not.
    # NOTE: the naive way to do this comparison is like `cmp al, 0`
    # However, it takes two bytes (or several in 32- and 64-bit modes) to encode the immediate operand.
    # Instead, `or`ing a register with itself leaves it unchanged, but also sets/clears the zero flag according to the value in that regiser.
    # This is just a little efficiency you'll see output from a compiler, and often in hand-written assembly as well, so it pays to be familiar.
  putstr.loop.bottom:
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
