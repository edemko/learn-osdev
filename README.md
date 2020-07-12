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

So far, I have one example: a do-nothing bootloader that picks up after BIOS, and then immediately halts.
Build with
    `zedo hello-os/build/bootloader-x86_64-bios/do-nothing.mbr`
    and run with
    `qemu-system-x86_64 -drive file=hello-os/build/bootloader-x86_64-bios/do-nothing.mbr,format=raw`.

## References

  * [Ciro Santilli's x86 Baremetal Examples](https://github.com/cirosantilli/x86-bare-metal-examples)
  * [GNU Assembler Manual](https://sourceware.org/binutils/docs/as/)
  * [GNU Linker Manual](https://sourceware.org/binutils/docs/ld/index.html)
  * [OSDev Wiki on Linker Scripts](https://wiki.osdev.org/Linker_Scripts)

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
