# References

## Overviews

There's a wonderful (but incomplete, more is the pity) book called [Writing a Simple Operating System from Scratch](https://www.cs.bham.ac.uk/~exr/lectures/opsys/10_11/lectures/os-dev.pdf) by Nick Blundell that seems to have been developed alongside his operating systems course.
I've used it to guide myself through a high-level overview of the bootloading process for the first time.
It begins from real mode and assumes BIOS support, which is still the most accessible boot sequence for beginners.

[A Bit of CMU Course Project](https://www.cs.cmu.edu/~410-s07/p4/p4-boot.pdf) gives a good overview of the booting sequence.
It begins from real mode and assumes BIOS support, which is still the most accessible boot sequence for beginners.


[Ciro Santilli's x86 Baremetal Examples](https://github.com/cirosantilli/x86-bare-metal-examples)

Yet another [bootloader example](https://appusajeev.wordpress.com/2011/01/27/writing-a-16-bit-real-mode-os-nasm/)

[Kazulauskas - A x64 OS](https://kazlauskas.me/entries/x64-uefi-os-1.html) using UEFI.

## Toolchain

### Assembler

The GNU Assembler is a "one-pass" assembler.
What I assume this means is that it does _no_ linking, or at least none of the interesting linking.
I believe instead it is designed to produce an object file with relocations (default ELF); only later will a dedicated linker resolve all the remaining references.
What this means in practice is that we run the assembler as normal to produce an ELF object.

  * [GNU Assembler Manual](https://sourceware.org/binutils/docs/as/)

Some GNU Intel-syntax quirks:
  * [Load an absolute address with `mov` in GNU as](https://stackoverflow.com/a/57212627)
  * [`OFFSET` in gnu as](https://stackoverflow.com/questions/1669662/what-does-offset-in-16-bit-assembly-code-mean)

### Linker

  * [GNU Linker Manual](https://sourceware.org/binutils/docs/ld/index.html)
  * [OSDev Wiki on Linker Scripts](https://wiki.osdev.org/Linker_Scripts)

Producing a raw binary file for use as a boot sector isn't as straightforward in the GNU toolchain as in (say) `nasm` (due to GNU `as` being single-pass).
Instead, it is recommended to write and use a special (GNU) linker script for this purpose.
I've seen some shortcuts like `ld -Ttext 0x7C00 --oformat binary -o fo.mbr foo.o` to accomplish this, but watch out!
It seems like `-Ttext` is not a single-character `-T` plus argument `text`; instead it is a multi-character argument name (but with only one dash just for confusion!) that takes a hexadecimal number as its argument.
I'm just pointing this out because its unconventionality makes it easy to miss while skimming for a quick solution.
In any case, using the/a default `text` script isn't customizable, so it's recommended to build your own.
One the plus side, one you have your own, you don't have to make concessions for quick-and-dirty hacks: you just have something that works well.

### Object File Manipulation

TODO objdump, objcopy, &c

You'll get bad disassembly running `objdump -D` on 16-bit code.
Instead, use `objdump -D -mi386 -Maddr16,data16`.
Additionally, adding a `-b binary` argument can get at the code in flat executables, but disassembling an ELF gets you the debugging symbols.

### Debugger

  * [GNU Debugger Manual](https://sourceware.org/gdb/onlinedocs/gdb/index.html)
  * [OSDev Wiki on Kernel Debugging](https://wiki.osdev.org/Kernel_Debugging)

#### Super-speed `gdb` tutorial

Run the emulator with remote debugging: `qemu -s -S <img>`
Then (in another terminal, or background qemu) start gdb: `gdb`.
Then set a break point at the start of the bootloader `break *0x7C00` and then `continue`.
(Shortcuts are `b` for break, `c` for continue.)
Execution will pause just before your bootloader begins running.

Use `info registers <reg names...>` to inspect registers.
Use `si` to step a single instruction.
If you're about to call in interrupt routine, you can set a breakpoint for after it returns then continue.

Use `x/i $pc` to show the current instruction disassembly, or `display/i $pc` to show it every tiem the debugger pauses.
Other registers can also be inspected: `x $esi` for example.
If a value in a register is unexpected, it can be overwritten with e.g. `set $si = 0x714`.


## Architecture of the x86-Family

  * [AMD64 ArchitectureProgrammer’s Manual Volume 2: System Programming](https://www.amd.com/system/files/TechDocs/24593.pdf)

### Cheatsheets and Overviews

  * [x64 Cheat Sheet](https://cs.brown.edu/courses/cs033/docs/guides/x64_cheatsheet.pdf)
  * [OSDev Wiki on x86_64 Registers](https://wiki.osdev.org/CPU_Registers_x86-64)
  * [Wikibooks x86 Architecture](https://en.wikibooks.org/wiki/X86_Assembly/X86_Architecture)

### Secondary Instruction References

  * [Felix Cloutier's reference](https://www.felixcloutier.com/x86/)
  * [http://ref.x86asm.net/](http://ref.x86asm.net/)
  * [c9x.me](https://c9x.me/x86/index.html)

### Some Traps for the Novice

  * [Real-mode addressing mode limitations](https://stackoverflow.com/a/34345858)

### Tricks

  * [A Far Call Trick](https://wiki.osdev.org/Far_Call_Trick)

## Bootloaders

### BIOS

BIOS is a "de facto" interface with variations implemented by motherboard firmware in IBM PC clones.
Circa 2020, it will no longer be available on new machines, instead replaced with UEFI without legacy support.

  * [General Tips for Bootloader Development](https://stackoverflow.com/a/32705076)
  * [CPU State After BIOS Hands-off](https://stackoverflow.com/a/43397557)

  * [IBM Technical Reference from Apr 1987](http://classiccomputers.info/down/IBM_PS2/documents/PS2_and_PC_BIOS_Interface_Technical_Reference_Apr87.pdf)
  * [Ralf Brown's Interrupt List](http://www.cs.cmu.edu/~ralf/files.html)
  * [Gabriele Cecchetti](http://www.gabrielececchetti.it/Teaching/CalcolatoriElettronici/Docs/i8086_and_DOS_interrupts.pdf)
    — technically is a reference for a particular emulator, but the information is good nonetheless.

  * [OSDev Wiki](https://wiki.osdev.org/BIOS)
  * [SeaBIOS' Developer Links Page](https://www.seabios.org/Developer_links) links to more BIOS-related information

### UEFI

  * [UEFI Programming - First Steps](http://x86asm.net/articles/uefi-programming-first-steps/)

### Multiboot

What is this? I've seen it referenced…

## Drivers

### ATA Disk Drivers

* [ATA Read/Write Sector Example](https://wiki.osdev.org/ATA_read/write_sectors)


## Articles and Acronyms/Initialisms

When in doubt, read it aloud.
Use "a" before words that start with a consonant sound, and "an" before words that start in a vowel sound.
Acronyms and initialisms are strings of letters that stand for a longer phrase;
acronyms are pronounceable as a single word in English, initialisms are spelled out letter-by-letter.

  * BIOS is an acronym starting with a consonant: "a BIOS"
  * UEFI is an initialism starting with a consonant sound (yes, "y" counts in this situation): "a UEFI"
  * XML is an initialism starting with a vowel sound: "an XML"

## Weird Junk

So, I've read in a couple places that the machine code `eb XX` is a relative jump.
However, in gdb+qemu, in real mode, this looks very close to an absolute jump.
And then, if I assemble 32-bit and 16-bit code for a halt routine, they are identical.
I have no idea what's going on, really.
Also, there's some weird behavior in gdb+qemu after I send SIGINT while the processor is halted:
the interrupt puts the ip at the next instruction, but step-instruction just hangs until another sigint, at which point the instruction (a jump in all test cases so far) seems not to have been executed.
