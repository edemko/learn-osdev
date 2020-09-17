# Nostalgios Sourcefiles Map

Portable code is in `include` (header files) and `src` (implementations).
All platform-specific code is isolated into its own folder (tree).
The names we use for different platforms (and the names we use for platform-specific folders) are given in the list below.
Not all of these are targeted at the moment, but the names are reserved for later use.

  * `x86_64`: Generic 64-bit x86 processors (i.e. both amd65 and intel64)
  * `amd64`, `intel64`: AMD64 and Intel64 have very minor differences;
    we try not to exploit these differences, but if we must, these are the terms we'll use
  * `x86`: 32-bit x86 processors
  * TODO target more architectures

Some architectures accrue a few standard interfaces on top of them (e.g. BIOS vs. VGA vs. VBE under x86).
These differences are also reflected in the source tree.

After (lower in the filesystem hierarchy) the platform/sub-platform distinction, we distinguish between bootloader and kernel code.
The kernel code is as platform-agnostic as we can reasonably make it, so there are no further distinctions after it.
Bootloader code, however, may conform to varying standards of disk layout, so these are distinguished within the bootloader directory.
The reason we separate out kernel/bootloader later than platform is because code useful in the bootloader may also be usefully re-compiled for use in the kernel.

For example:
  * `x86_64/bios/bootloader/` contains code (usually libraries) for booting under BIOS (which is a sub-platform of x86_64)
  * `x86_64/bios/bootloader/mbr/` contains code for bootloaders that operate on disks with a Master Boot Record (which assumes BIOS)
  * `x86_64/uefi/bootloader/gpt/` contains code for UEFI bootloaders (which (at time of writing) only use GPT partitioning)
  * `x86_64/bios/` contains code (usually libraries) using BIOS utilities (which is a sub-platform of x86_64)
  * `x86_64/vga/` contains code (usually libraries) which rely on the VGA interface


## Sub-platforms in the x86-Family

  * `bios`: TODO
  * `vga`: TODO
  * `vbe`: TODO
  * `uefi`: TODO
