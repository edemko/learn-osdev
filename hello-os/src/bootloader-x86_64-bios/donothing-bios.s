# This program does nothing, but is meant to be entered directly from BIOS, and is therefore a BIOS-based bootloader.
# It's really here just to get the BIOS to hand off to a _minimum_ program.
# That said, I have used some better practices than the _true_ minimum program.


# The GNU Linker uses ATT syntax by default, but the official ISA documentation uses (unsurprisingly) Intel syntax.
# So, I'll be using intel syntax for easier access to documentation.
# Besides, I personally like destination-first argument order, and not prefixing register names with sigils.
# Note the `noprefix` argument, which let's us write more like actual Intel syntax than a weird mash-up of ATT and Intel.
# (See https://stackoverflow.com/a/46749011 for some more notes on GAS Intel vs. true Intel)
# There is one thing to note, though: GNU still uses 0xDEADBEEF sytnax for hexadecimal as opposed to DEADBEEFh syntax;
# dor me, this is highly preferable, since I can see from the start of reading a number what base it's in.
.intel_syntax noprefix

# This is executable code, so it goes in a `.text` section by convention.
# This section name could be changed, if desired, but you would have to adjust the linker script to match.
.section .text

# Emit machine code for 16-bit real-mode (or 16-bit protected, but we're not using that here).
.code16

# Although we don't _need_ to give our entry-point a name, it's nice to be able to see it in decompilers and debuggers
# I've gone with `bootloader`, but there's no signifigance behind the choice.
.global bootloader
bootloader:

# There isn't much you can be guaranteed of about the processor state when BIOS jumps you your bootloader.
# Although we won't be using any of these features here, I'll implement and document them anyway just to show what would be best.
# Skipping these steps is likely to work on qemu, but on real hardware, skipping them might mean crashes,
# which is annoying this early in the boot process.

# We don't want to be interrupted while getting set up, so we disable interrupts.
cli # diable interrupts

# Although we know the bootloader is loaded at linear memory location `0x07C00`, because of real-mode segmentation,
# this could be represented with a `cs:ip` of `0x0000:0x7C00` as one might expect, or `0x07C0:0x0000`, or anything in-between.
# To canonicalize this, we do is a far-jump to the next instruction.
# I've also seen this done as `jmp 0x07C0:0x0000`, but I'm not sure what that gains for a bootloader
# WARNING: Although this syntax is accepted, I'm not really sure what's happening if you set `cs` to the start of the bootloader.
# gdb doesn't let me see ip, but it reports `rip` as I'd expect, so it _might_ be fine…
jmp 0x0000:bootloader.canonPoint
bootloader.canonPoint:

# With the code segment `cs` register now set, let's set the other segment registers.
# I've taken the convention that they should all be zero.
# After all, since any x86_64 system will quickly switch to a 64-bit mode anyway, which has a non-segmented memory model.
xor ax,ax # we're not guaranteed the contents of ax, so clear it
mov ds, ax # then we can indirectly move `ax` into the segment registers
mov es, ax

# We'll very likely want to be able to call functions, so we need to set up `ss:sp` appropriately.
# For this, we need to choose some unused memory that will be out of the way of where we want to eventually load our kernel.
# This leaves the (linear) ranges 0x00500–0x07BFF, 0x07E00–0x9FFBF, and addresses above 0x1000000.
# The bytes in the range 0x07C00–0x07E00 are already taken by this very bootloader code.
# Those high addresses aren't rechable in real mode, so let's ignore them.
# I'd like to avoid a stack overflow overwriting bootloader code, but also leave some room for loading a second-stage bootloader.
# If I pick a stack in the range 0x80000–0x8FFFF, this leaves 0x07E00–0x7FFFF for a heap.
# The only way to reach this memory in real mode is to set the stack segment `ss` at 0x8000.
# Since push/pop instructions adjust `sp` but not `ss`, a stack overflow won't re-write code.
# We start the stack pointer at zero because when the first push happens,
# the `ss` will be decremented by 2—which overflows for get `FFFE`—and it is there that
# the pushed value will be written; so the first pushed value will really end up at linear address 0x8FFFE as we want.
# It's important to ensure the stack is always 2-byte aligned, since unaligned memory accesses can be much slower.

mov ax, 0x8000 # set the stack segment register
mov ss, ax     # again, these must be loaded indirectly from a general-purpose register
xor ax, ax # set sp to zero
mov sp, ax # and as a side-effect, we've also got `ax` zeroed out

# Most of the FLAGS register are for arithmetic flags, which are contantly flipping around, so we don't care what they look like.
# The remaining bits contain the interrupts and direction register.
# The interrupt enable bit we're already dealing with, but the direction bit should be initialized.
# I've chosen forward here, since I expect it to be used with text which are naturally traversed forwards.
# There are a few other bits, but I don't thing we care about them (but TODO anyway).
cld # set direction forward for autoincrement instructions such as `lods`

# We're done initializing now, so…
sti # re-enable interrupts

# At this point, the values of general-purpose registers could still be garbage.
# In fact, I don't even want to say that `ax` is zero, since small changes in the above code—such as for a bugfix—migth change that.
# In general, it's best for each stage to assume very little about the state of general-purpose registers.
# One thing that BIOS does guarantee (unless we're talking _really_ old school) is that the `dl` register contains
# the drive number whence the bootloader was read.
# For this reason, it's important to preserve the `dl` register until we're ready to load more code from disk.

# So far, this code is compatible with even very old x86 ISAs, such as the 8086.
# To do this, we sacrificed initialization of the `fs` and `gs` segment registers which were only added in the 80386.
# My philosophy is that 16-bit x86 has enough registers to handle entering protected mode without difficulty,
# so I'll only initialize 32-bit features once we land in a 32-bit mode.


# Some other examples might just give `halt: jmp halt`, but this means the CPU is continually processing the same instruction.
# This method allows the processor to "sleep".
# If an interrupt is generated, it will be ignored if possible, but if not, we'll make sure that we end up just waiting for another interrupt again.
halt:
  cli            # mask out as many interrupts as possible
  hlt            # wait for an interrupt
  jmp bootloader # if an interrupt fires anyway, just loop while doing nothing
