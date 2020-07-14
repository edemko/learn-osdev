# learn-osdev

This is a repository full of notes to myself regarding operating system development.
In this case, the code _is_ the documentation, at least for the code I'm learning.

The build system is zedo-based.
If you don't already have a working zedo on your system, you can setup a minimal implementation with:

```sh
git submodule update --init zedo-shim
export PATH+=":$PWD/zedo-shim/bin"
```

I'm assuming a GNU toolchain (gcc, as, ld, objdump, &c).
The examples are tested on QEMU.


## Examples

So far, I only have some primitive hello-world-style bootloader examples.

### Simple BIOS Bootloaders

These are example programs that fit into (and are run from) the master boot record.
I suppose a real bootloader would actually load a kernel, but these don't, and I'm still going to call them bootloaders.
They are in `hello-os/src/bootloader-<arch>-bios/<example>.s`, though for now I only cover `x86_64`
    (but to be fair, real and long mode examples probably also work for the appropriately earlier x86-family processors).

  * `donothing`: Just initializes and halts immediately on booting.
    It stays halted even if the processor gets interrupts, which some examples can't say of themselves.
  * `hello`: Uses (deprecated) BIOS calls to print `Hello BIOS!` on-screen.
  * `selfdump`: Uses BIOS calls to print its own machine code in hexadecimal.

Build these examples with
    `zedo hello-os/build/bootloader-x86_64-bios/<example>.mbr`
  and run with
    `qemu-system-x86_64 -drive file=hello-os/build/bootloader-x86_64-bios/<example>.mbr,format=raw`.
Building involves a GNU linker script `hello-os/src/bootloader-x86_64-bios/mbr.ld`, so check that out.

### Stage One BIOS Bootloaders

Now I'm onto actual bootloaders; you know: things that load more code to continue booting.
They are also in `hello-os/src/bootloader-<arch>-bios/<example>.s`.

These examples are designed so that several stage-1 programs can use the same stage-0 bootloader.
However, I plan for there to be three stage-0 bootloaders which load a 16-, 32-, or 64-bit stage-1 program.
These bootloaders are at `stage0.rm.s`, TODO `stage0.pm.s`, and `stage0.lm.s` respectively.
Each example also has hese `.{rm,pm,lm}.s` extensions as well, which helps the build system to pair up a stage-1 with an appropriate stage-0.

Real-mode examples:

  * `donothing.rm.s`: Immediately halts.
  * `hello.rm.s`: Uses (deprecated) BIOS calls to print `Hello BIOS!` on-screen.

I haven't gotten to protected or long modes yet.


## References

There's a wonderful (but incomplete, more is the pity) book called [Writing a Simple Operating System from Scratch](https://www.cs.bham.ac.uk/~exr/lectures/opsys/10_11/lectures/os-dev.pdf) by Nick Blundell that seems to have been developed alongside his operating systems course.
I've used it to guide myself through a high-level overview of the bootloading process for the first time.

  * [Ciro Santilli's x86 Baremetal Examples](https://github.com/cirosantilli/x86-bare-metal-examples)
  * [GNU Assembler Manual](https://sourceware.org/binutils/docs/as/)
  * [GNU Debugger Manual](https://sourceware.org/gdb/onlinedocs/gdb/index.html)
  * [GNU Linker Manual](https://sourceware.org/binutils/docs/ld/index.html)
  * [OSDev Wiki on Kernel Debugging](https://wiki.osdev.org/Kernel_Debugging)
  * [OSDev Wiki on Linker Scripts](https://wiki.osdev.org/Linker_Scripts)

And now, some x86 ISA references:

  * [AMD64 ArchitectureProgrammer’s Manual Volume 2: System Programming](https://www.amd.com/system/files/TechDocs/24593.pdf)
  * [Felix Cloutier's reference](https://www.felixcloutier.com/x86/)
  * [http://ref.x86asm.net/](http://ref.x86asm.net/)
  * [c9x.me](https://c9x.me/x86/index.html)
  * [OSDev Wiki on x86_64 Registers](https://wiki.osdev.org/CPU_Registers_x86-64)

And some BIOS references:

  * [A Bit of CMU Course Project](https://www.cs.cmu.edu/~410-s07/p4/p4-boot.pdf) - gives a good overview of the booting sequence
  * [Gabriele Cecchetti](http://www.gabrielececchetti.it/Teaching/CalcolatoriElettronici/Docs/i8086_and_DOS_interrupts.pdf)
  * [IBM Technical Reference from Apr 1987](http://classiccomputers.info/down/IBM_PS2/documents/PS2_and_PC_BIOS_Interface_Technical_Reference_Apr87.pdf)
  * [OSDev Wiki](https://wiki.osdev.org/BIOS)
  * [Ralf Brown's Interrupt List](http://www.cs.cmu.edu/~ralf/files.html)
  * [SeaBIOS' Developer Links Page](https://www.seabios.org/Developer_links)
  * [General Tips for Bootloader Development](https://stackoverflow.com/a/32705076)
  * [CPU State After BIOS Hands-off](https://stackoverflow.com/a/43397557)

Some notes to self for further documentation:

  * [Laod an absolute address with `mov` in GNU as](https://stackoverflow.com/a/57212627)
  * [`OFFSET` in gnu as](https://stackoverflow.com/questions/1669662/what-does-offset-in-16-bit-assembly-code-mean)
  * [Real-mode addressing mode limitations](https://stackoverflow.com/a/34345858)

Since I can't get a far jump working under gas+qemu as far as gdb can tell, here's a collection of far-call related stuff and examples of it apparently working for people:
  * [A Far Call Trick](https://wiki.osdev.org/Far_Call_Trick)
  * [A bootloader example](https://appusajeev.wordpress.com/2011/01/27/writing-a-16-bit-real-mode-os-nasm/)

Here's some links I haven't really sued yet, but they could be useful as I graduate away from BIOS programming:

  * [ATA Read/Write Sector Example](https://wiki.osdev.org/ATA_read/write_sectors)
  * [UEFI Programming - First Steps](http://x86asm.net/articles/uefi-programming-first-steps/)
  * [Kazulauskas - A x64 OS](https://kazlauskas.me/entries/x64-uefi-os-1.html)

## Toolchain Notes

TODO: I bet I should be explicitly using a cross-compilier toolchain.
For the moment, I'm on amd64, and am targeting a freestanding amd64 with assembly, so it doesn't matter much yet, but it will soon enough!

The GNU Assembler is a "one-pass" assembler.
What I assume this means is that it does _no_ linking, or at least none of the interesting linking.
I believe instead it is designed to produce an object file with relocations (default ELF); only later will a dedicated linker resolve all the remaining references.
What this means in practice is that we run the assembler as normal to produce an ELF object.

Producing a raw binary file for use as a master boot record isn't as straightforward in the GNU toolchain as in `nasm` (due to GNU `as` being single-pass).
Instead, it is recommended to write and use a special (GNU) linker script for this purpose.
I've seen some shortcuts like `ld -Ttext 0x7C00 --oformat binary -o fo.mbr foo.o` to accomplish this ,but watch out!
It seems like `-Ttext` is not a single-character `-T` plus argument `text`; instead it is a multi-character argument name (but with only one dash just for confusion!) that takes a hexadecimal number as its argument.
I'm just pointing this out because its unconventionality makes it easy to miss while skimming for a quick solution.
In any case, using the/a default `text` script isn't customizable, so it's recommended to build your own.
One the plus side, one you have your own, you don't have to make concessions for quick-and-dirty hacks: you just have something that works well.

You'll get bad dissasebly running `objdump -D` on 16-bit code.
Instead, use `objdump -D -mi386 -Maddr16,data16`.
Additionally, adding a `-b binary` argument can get at the code in flat executables, but disassembling an ELF gets you the debugging symbols.

### Super-speed `gdb` tutorial

Run the emulator with remote debugging: `qemu -s -S <img>`
Then (in another terminal, or background qemu) start gdb: `gdb`.
Then set a break point at the start of the bootloader `break *0x7C00` and continue `c`.
Execution will pause just before your bootloader begins running.
Use `info registers <reg names...>` to inspect registers.
Use `si` to step a single instruction.
If you're about to call in interrupt routine, you can set a breakpoint for after it returns then continue.
If a value in a register is unexpected, it can be overwritten with e.g. `set $si = 0x714`.

### Something Weird

So, I've read in a couple places that the machine code `eb XX` is a relative jump.
However, in gdb+qemu, in real mode, this appears to be an absolute jump.
I have no idea what's going on, really.
Also, there's some weird behavior in gdb+qemu after I send SIGINT while the processor is halted:
the interrupt puts the ip at the next instruction, but step-instruction just hangs until another sigint, at which point the instruction (a jump in all test cases so far) seems not to have been executed.
