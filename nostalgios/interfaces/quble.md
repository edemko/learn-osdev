# Quick Bootstrap Layout and Execution (Quble) Protocol

The Quick Bootstrap Layout and Execution (Quble) Protocol is a standard for how to hand-off the boot process between the end of execution of a IBM PC-compatible BIOS and the start of execution of the next stage, which may be a small operating system or stage one bootloader.
It specifies a format for the bootsector and makes guarantees about the state of the system when the next stage is entered.
Its design emphasizes speed of execution to allow user software to begin quickly, transparency with existing BIOS routines (which unfortunately must be accommodated in their not-truly-standardized state), and simplicity of interface so that it serves as a reliable foundation for user software.

The key idea is simply to locate the next stage on on the same disk as the bootsector, regardless of that disk's partitioning or file systems.
It is assumes that the file system (if any) will be able to sector-align the file holding an OS kernel or stage one bootloader.
By assuming nothing more than sector-alignment for files, we avoid the need for bootsectors to implement their own disk partition and.or file system drivers.
This should leave a lot of space for bootstrap code, which can then be used to ensure a reasonable environment for executing the next stage of booting.


## Quble Bootsector Layout

The Quble Protocol specifies a binary format for bootsectors under IPM PC-compatible BIOS.
Since it builds on BIOS, it requires a (little-endian) 0xAA55 signature at the end of the bootsector.
To this, Quble adds a four-byte data structure called the "Bootchain".
The bootchain specifies whence to load a Quble-compatible binary executable from disk (the same disk the bootloader resides on).
Additionally, ten bytes are reserved in the bootsector for various purposes:

  * a byte to save the `dl` register (which hold the disk number whence the bootsector was loaded) before the stack is initialized
  * a byte which specifies a Quble variant code (see below)
  * eight bytes whose semantics is determined by the setting of variant, but is usually a checksum

A bootsector complies with the Quble Protocol when it has the following layout:

| Address (Hex) | (Decimal) | Description         | Size (bytes) |
|---------------|-----------|---------------------|--------------|
| +00  | 0   | bootstrap code                              | 496 |
| +1F0 | 496 | Quble Bootchain (see below)                 | 4   |
| +1F4 | 500 | reserved; usage determined by variant       | 8   |
| +1FC | 508 | variant code                                | 1   |
| +1FD | 509 | reserved space to save `dl`                 | 1   |
| +1FE | 510 | bootsector signature 0xAA55 (little-endian) | 2   |

Quble is not compatible with Master Boot Record format used on DOS machines.
Unfortunately, we are not able to recommend any bytes that would produce an obviously-invalid MBR.
As such, the user is once again reminded to be very careful with software that manipulates the bootsector.

### Quble Bootchain

The Quble Bootchain consists of four bytes.
It contains the cylinder head and sector where the next stage begins, as well as the length of the next stage in sectors.

| byte | semantics            |
|------|----------------------|
| 0 | sector                  |
| 1 | cylinder (a.k.a. track) |
| 2 | head                    |
| 3 | sector count (less one) |

The size of the next stage is limited to the range 1–65 (see Quble Hand-off below).
To ease error-detection, the actual number of sectors loaded is therefore actually one greater than the number in the sector count field.
If the sector count field contains a number greater than 64, this may indicate an uninitialized value, and Quble bootloaders are recommended to abort.
It is also recommended to use 0xFF as an uninitialized value for the sector count.

This layout is designed not for human readability (which might use CHS+size order), but for being easily checked for errors and loaded into the correct BIOS position.
Note that a single `mov cx, bootchain` will setup both the sector and cylinder arguments to the BIOS read-from-disk routine.

### Quble Variants

TODO introduce/document reasons for variants better

A Quble bootloader is only required to understand Variant Zero, and one other variant.
If the variant code stored at +1FC is not expected, it is recommended to treat this as a fatal error.

All variants not defined here are reserved for future use.
Although vendors might ship software which relied on undefined variants, this is incorrect; only variants 0xF0–0xFF may be used for vendor-specific extensions.

The fields of the Quble reserved space are given from +1F4 up.
If The structure does not require all 8 bytes, the remaining bytes are free space.

| Variant Code (hex) | Name | Semantics for +1F4–+1FB   |
|--------------------|------|---------------------------|
| 00 | Variant Zero                  | free space       |
| 04 | 32-bit simple xor checksum    | 4-byte checksum  |
| 05 | 32-bit simple add checksum    | 4-byte checksum  |
| 06 | 64-bit simple add checksum    | 8-byte checksum  |
| 07 | 64-bit simple add checksum    | 8-byte checksum  |
| 08 | Fletcher-32 checksum          | 4-byte checksum  |
| 0A | Fletcher-64 checksum          | 8-byte checksum  |
| F0–FF | Vendor-specific extensions | vendor-specific  |


## Quble Hand-off

The Quble Protocol specifies parts of the processor state and memory map the next stage loaded by a Quble bootloader can rely on.
It defines the values in various registers, defines the use for some areas of memory, provides an initialized stack, and initializes a video mode.

The next stage executable is loaded beginning from linear address 0x7E00 (immediately after where the bootsector was loaded).
This stage can range up through 0xFFFF inclusive, which represents 65 sectors, or 32.5KiB.
Execution of the next stage begins from 0:0x7E00, which is the starting bytes of the executable addressed from segment zero.
The limitation on the size of the next stage executable is to ensure that it will fit in segment zero just after the bootsector.
There is nothing stopping the next stage from loading additional sectors if necessary, but it is likely that 32.5KiB is most likely sufficient space to implement disk and file system drivers; it is therefore recommended that if an OS kernel does not fit into the Qubl next stage, that the next stage be a stage one bootloader.

Quble bootloaders must preserve the disk number in `dl` exactly as BIOS loaded it.
The `di` register contains the first address (in segment zero) not loaded by the Quble bootloader, or zero if the maximum 65 sectors were loaded.
The general-purpose segment registers `ds` and `es` are set to zero.
Interrupts are enabled and direction is set to forward.
The values of the other registers and flags are undefined.
Registers introduced with the 80386 are not defined specifically to allow Quble implementations to run on the earlier 16-bit processors.

An empty stack is initialize at addresses `0x0800:0x0000` through `0x0800:0xFFFF`.
Recall that the 80x86 processor family's stack grows downwards, so this means that `ss:sp = 0x0800:0x0000`, and the first push instruction in the next stage will cause wraparound of `sp`.
We have decided to use an entire segment for the stack to offer a limited form of stack overflow protection: at least pushes and pops will not corrupt memory outside the stack.
Nevertheless, it is possible for instructions to corrupt the stack on overflow, which may then cause other instructions, such as `ret` and `retf` to behave unpredictably.

In choosing areas to load the next stage and initialize the stack, Quble avoids overwriting any existing BIOS data structures.
In addition, the Quble data structures in the bootsector are required to be preserved for later reference.
In practice, it is likely that the entire bootsector will be preserved, as there is not much reason to place self-modifying code within it.

The 80286 introduced the A20 gate, which must be enabled to gain access to odd-numbered megabytes.
There are several methods to enable this gate, which can be quite fraught.
Quble will check if BIOS enabled the A20 line, but it _must not_ attempt to enable it.
As fraught as enabling the A20 line is, it is even more difficult to _disable_ it.
If Quble bootloaders were allowed to enable the A20 gate on their own, this would prevent 8086, 8088 and 80186 code that relies on 1MiB wrap-around from being loaded by Quble.
If the A20 line is disabled, the bootsector signature in memory `0x7DFE` will be overwritten with zero.
It is therefore recommended to _not_ write the bootsector back to disk; if the A20 line is not enabled, this will make the drive non-bootable if this memory location is not restored with the bootsector signature.

Quble will initialize video to mode 0x03, which is a 16-color 80x25 text mode.
Quble will clear the screen before entering the next stage.
Diagnostic messages that a Quble bootloader might display prior to successfully entering the next stage should not convey information of lasting importance.

If a Quble bootloader detects any errors, it should halt the processor after optionally printing diagnostic messages to the screen.


## Quble Libraries

TODO should I offer some libraries to help write quble bootloaders (message printing, checksum algorithms)?
TODO what about libraries to pick up after the stage zero bootloader (e.g. stuff to enter protected mode)?
