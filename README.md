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

Protected-mode examples:

  * `donothing.pm.s`: Immediately halts.

I haven't gotten to long mode yet, nor (obviously) have I done much interesting in stage 1.
