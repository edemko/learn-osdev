# The GNU Linker uses ATT syntax by default, but the official ISA documentation uses (unsurprisingly) Intel syntax.
# So, I'll be using intel syntax for easier access to documentation.
# Besides, I personally like destination-first argument order, and not prefixing register names with sigils.
.intel_syntax

# This is executable code, so it goes in a `.text` section by convention.
# This section name could be changed, if desired, but you would have to adjust the linker script to match.
.section .text

# Emit machine code for 16-bit real-mode (or 16-bit protected, but we're not using that here).
.code16

# Although we don't _need_ to give our entry-point a name, it's nice to be able to see it in decompilers and debuggers
# I've gone with `bootloader`, but there's no signifigance behind the choice.
.global bootloader
bootloader:
  cli            # mask out as many interrupts as possible
  hlt            # wait for an interrupt
  jmp bootloader # if an interrupt fires anyway, just loop while doing nothing
