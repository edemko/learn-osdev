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
    `zedo hello-os/build/bootloader/do-nothing.mbr`
    and run with
    `qemu-system-x86_64 -drive file=hello-os/build/bootloader/do-nothing.mbr,format=raw`.

## References

  * [Ciro Santilli's x86 Baremetal Examples](https://github.com/cirosantilli/x86-bare-metal-examples)
  * [GNU Assembler Manual](https://sourceware.org/binutils/docs/as/)
  * [GNU Linker Manual](https://sourceware.org/binutils/docs/ld/index.html)
  * [OSDev Wiki on Linker Scripts](https://wiki.osdev.org/Linker_Scripts)
