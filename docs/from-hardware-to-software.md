# From Hardware to Software

The entire goal of the boot process is to take a piece of hardware and expose software through it.
That is, you press a power button (hardware), and in a few seconds you have access to an operating system (software).
Or at least, that's what consumers think of, but the range of possibilities in both hardware and software are enormous, especially when you start designing and building your own.
It therefore would be a good idea to settle some definitions, and also close in on a definition for the elusive "firmware".

  * Hardware: You need a lab to create of modify this stuff.
    It could be as simple as a soldering gun and some spare components,
    but if you intend to work on integrated chips directly,you'll want a bunch of high=precision, highly-specialized tools.
    Ultimately though, the fidelity of the hardware you make to your design is dependent on your ability to manipulate physical objects.
  * Software: Standard consumer equipment puts bytes on a storage medium.
    The medium is usually read-write, like a floppy drive, hard drive, or flash drive.
    It can be read-only, though, like a CD-ROM or punch cards.
    Most of the time, an existing computer system does it, but in early systems, you might use a card-punch to punch software onto punch cards :P
    In any case, the fidelity of the software you design is 
  * Firmware: Firmware is software that requires specialized tools to modify, or perhaps it's hardware that doesn't require craftsmanship?
    In any case, firmware is bytes stored on a medium that isn't normally writable or removable without specialized equipment.
    It serves as an interface allowing the hardware to execute software and the software to control the hardware.
    Since the hardware doesn't change easily, usually not much effort goes into allowing the firmware to change easily.
    This is, of course, assuming the firmware is modifiable at all: the Apollo guidance computer firmware was stored on core-rope memory, which would require re-weaving to change.
    Nowadays, hardware bugs have become more well-known, and vendors design their firmware to be updated from software, though
    the consumer—or even the prosumer—has no real conception of what is really going on here.

    For a modern machine that doesn't support "firmware updates", the storage for firmware normally resides on an integrated chip which has EPROM or flash memory that the system cannot write to on its own.
    You'll need a "programmer", which clips onto this chip on one end, and usually leads back to a regular computer on the other.
    All the programmer device needs to do is apply the correct voltages to the correct pins in the correct order to transfer bytes from consumer storage/memory into the chip's storage.


## The BIOS-to-Software Interface

TODO the are just notes so far

The BIOS loads sector zero of a disk; this is the "boot sector".
It is not to be confused with the "Master Boot Record" (MBR), which is a specific format (more properly, family of formats) of boot sector.

## The Master Boot Record

An MBR contains at least bootstrap code, a very simple partition table data structure, and two magic bytes.
Other members of this family might contain metadata, additional partition entries, checksums, and so on, but they are all backwards-compatible with the "classic" MBR.

TODO learn more about this family

## The UEFI-to-Software Interface

TODO learn UEFI
