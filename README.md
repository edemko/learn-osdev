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

Good references (or at least they look good) are in [references.md](references.md).
It has notes about hardware/firmware/software interfaces as well as toolchain information.

I'm hosting this in [github](https://github.com/Zankoku-Okuno/learn-osdev),
and using their "Pages" feature to publish out-of-band [documentation](https://zankoku-okuno.github.io/learn-osdev/) from the `docs` directory.
That's where the overview/reference documentation lives, but the most walkthrough-style documentation is in-line with the code.


## Examples

So far, I only have some primitive hello-world-style bootloader examples.

Whenever these can be build with `zedo <example>`, you should also be able to run them under qemu with `zedo <example>.run`, or as `zedo <example>.gdb` to allow GDB to connect on `:1234`.

### Simple BIOS Bootloaders

These are example programs that fit into (and are run from) the master boot record.
I suppose a real bootloader would actually load a kernel, but these don't, and I'm still going to call them bootloaders.
They are in `hello-os/src/bootloader-<arch>-bios/<example>.s`, though for now I only cover `x86_64`
    (but to be fair, real and long mode examples probably also work for the appropriately earlier x86-family processors).

Build these examples with `zedo hello-os/build/bootloader-x86_64-bios/<example>.bootsector`.
Building involves a GNU linker script `hello-os/src/bootloader-x86_64-bios/bootsector.ld`, so check that out.

  * `donothing`: Just initializes and halts immediately on booting.
    It stays halted even if the processor gets interrupts, which some examples can't say of themselves.
  * `hello`: Uses (deprecated) BIOS calls to print `Hello BIOS!` on-screen.
  * `selfdump`: Uses BIOS calls to print its own machine code in hexadecimal.


### Stage One BIOS Bootloaders

Now I'm onto actual bootloaders; you know: things that load more code to continue booting.
They are also in `hello-os/src/bootloader-<arch>-bios/<example>.<mode>.s`.

These examples are designed so that several stage-1 programs can use the same stage-0 bootloader.
I had planned for there to be three stage 0 bootloaders each hands off to stage 1 in one of real mode, protected mode, or long mode.
However, it turns out that even the protected mode is a little cramped, so I've canned the idea of also switching to long mode here.
Instead, I believe it is probably better engineering to only hand off to a real mode stage 1.

These bootloaders are at `stage0.rm.s`, and `stage0.pm.s`, for a real- or protected-mode stage 1 respectively.
Each example also has these `.{rm,pm}.s` extensions as well, which helps the build system to pair up a stage-1 with an appropriate stage-0.

Build these examples with `zedo hello-os/build/bootloader-x86_64-bios/<example>.<mode>.img`.
In addition to the `bootsector.ld` linker script used earlier, I also use `hello-os/src/bootloader-x86_64-bios/stage1.ld`.

Real-mode examples:

  * `donothing`: Immediately halts.
  * `hello`: Uses (deprecated) BIOS calls to print `Hello BIOS!` on-screen.

Protected-mode examples:

  * `donothing`: Immediately halts.
