# This bootloader does a little more than nothing: it says hello and then stops doing things.
# This file builds on the ideas of `do-nothing.s`, so understand that one first.
# I'm using the deprecated BIOS calls to do this, just so I have a retrocomputing example.
# There are other approaches: see TODO.


# There are a bunch of directives I'm using all over the place.
# These could be put into another file and shared, but such a library tends to get bigger than a newcomer wants to memorize.
# Instead, I'm writing it all out every time so that it's easy to see what's going on in every file without having to reference a separate file.
.intel_syntax noprefix

# This section is non-executable, initialized data.
# Although we've written it at the top, the linker script will re-arrange it so it will appear after the `.text` section.
.section .data
hellostr:
  # define a NUL-terminated ASCII string
  # I'm not sure why GNU decided to leave off the second "i", but the "z" stands for "zero",
  # which is often how the ASCII "NUL" character is referred to in practice.
  # Rest assured, there is a real name for this character, though!
  .asciz "Hello, BIOS!"

.section .text
.code16

.global bootloader
bootloader:
  # The calling convention for BIOS calls is to put the function code in `ah`,
  # additional arguments as instructed by the BIOS function,
  # and issue a specific interrupt.
  # A lot of display commands are under interrupt 0x10.

  # The first thing we want to do is clear the screen.
  # The BIOS may have left some information, but we don't want that cluttering up the screen.
  # To do this, we'll switch vide modes, which will clear the screen for us as well.
  mov ah, 0x00 # BIOS function = set video mode
  mov al, 0x03 # video mode argument = 80x25 text mode
  int 0x10     # call BIOS function

  # since we're making function calls, make sure the stack is set-up
  # mov bp, 0x8000
  # mov sp, bp

  # Before going on to character printing, I want to give an example of printing a single character on its own.
  jmp putexclam.end # To avoid actually executing the example, I'll jump over it
  putexclam:
    mov ah, 0x0E  # Set function code to print a character
    mov al, '!'   # The character to print goes in `al`.
    int 0x10      # call the graphics-related 
    jmp halt      # if we've actually gotten in here, let's make sure not to continue.
  putexclam.end:

  # Now then, we actually want to print a string to the screen.
  # Since this is such a common routine, I've built an optimized subroutine for it called `putstr`.
  # Here we just call it accordig to it's documented calling convention.
  # TODO I have no idea what `OFFSET` does, or why I need it in GNU (but not nasm), but without it, it loads the wrong address
  mov si, OFFSET hellostr # put the address of the string we want to print into `si`; in this case, it's at the `hellostr` label
  call putstr

  # That's all we want this bootloader to do, so we halt.
  # Ince this call is in "tail-position", we jmp instead of call: this is tail-call optimization.
  # Though really, since `halt` doesn't return, I'm not sure it quite counts, but it's the same idea.
  jmp halt


# Here's the definition for the `putstr` subroutine.
# You might have seen that I'm using the word "subroutine" instead of "function";
# I'm not sure there's any reall difference, but when we're at this low-level, I like to use "subroutine" by default and reserve "function" for pure functions.
# If a piece of code doesn't play nice with a stack, I might even call it a "procedure".
# Anyway, until we've established a calling convention, it's good to specify one for every function explicitly and document it.

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
    mov al, [si] # Load the next character as the argument to the BIOS print-character call
    inc si       # Point at the next character.
    # could also `lodsb`, which would be less code byes
    cmp al, 0    # Check if this character is NUL; exit if so, but print and continue if not
    # I often see `xor al, al`, which sets flags as well; but TODO I haven't checked if it's actually smaller/faster somehow
    # I mean, it probably avoid the immediate value and therefore saves a byte.
    jnz putstr.loop.top
  putstr.loop.bottom:
  ret


# CALLCONV halt
#| stop doing useful things
# no arguments
# does not return
halt:
  cli
  hlt
  jmp halt
