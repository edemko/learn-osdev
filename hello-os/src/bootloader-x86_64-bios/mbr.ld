/* This linker script for GNU ld which produces unadorned binary files suitable for use as a master boot record (MBR) as part of the BIOS booting process.
*/

/*
You might note that comments are as in old-school C: only block comments (slash-star ... star-slash) are allowed—not the more convenient line (double-slash) comments.
That said, I haven't (yet) seen many linker scripts with any comments at all <_<
*/

/*
First we set the output format.
If this weren't set to `binary`, there would be all sorts of executable/library headers wrapping up our MBR.
The MBR is most convenient to work with in plain binary, so we don't want any of that.
*/
OUTPUT_FORMAT(binary)

/*
Normally, I would provide an entry point, but this isn't necessary when the output is binary.
Instead, the BIOS will simply begin execution from the beginning of the output binary.
*/

/*
The essential ingredient of a linker script is a sections directive.
*/
SECTIONS {
  /* The special symbol `.` is the location counter, which tracks which address the output will be loaded.
  Note that this is *not* the location in the output file.
  In this case, BIOS will load our master boot record to address 0x7C00, so we set the current location counter here.
  */
  . = 0x7C00;

  /*
  In out case, we only have one output section: the master boot record.
  It doesn't much matter what we name it, since the name won't be output anywhere; I've gone with `.mbr` because I think it's fairly descriptive.
  */
  .mbr : {
    /*
    We include the text sections of all input files first.
    TODO I believe the order of the files on the command-line is relevant, so pass the one with the bootloader's entry-point first.
    For now, I'm just keeping everything in the same object file, so this has only been used with one input file.
    */
    *(.text);

    /* After the text segments, we put any data segments. */
    *(.data);

    /*
    Once we've included all the useful code, we need to place the magic 0xAA55 at the end of the MBR.
    Since the MBR is 512 bytes long, we move to position 510 and output the two bytes.
    I'm using `SHORT` instead of two `BYTE` just so that the linker can handle endian-ness instead of me;
    since x86 is little-endian, this will show up in the output as the byte sequence `0x55 0xAA`, so don't be alarmed.

    It's worth noting that `ld` will refuse to move backwards,
    so if the text and data sections we link in are more than 510 combined, then `ld` will fail.
    The error message is `cannot move location counter backwards`.

    It seems that the special `.` symbol actually _does_ move in the output when it's used here, though I couldn't find documentation to this effect (or, now that I think about it, about `.` outside an output section statement either!).
    In any case, `.` is a byte offset from the containing object; the section directive above, but the `mbr` section here:
    boy was I in for a surprise when I guessed otherwise and set it to 0x7DFE!
    */
    . = 510;
    SHORT (0xAA55);
  /*
  Some extra attributes can be set at the end of an output section.
  Here, we want to set the "fill" for the section: this value will be output when sections of the output have been skipped over.
  I've set the fill to be zeros just so that `hexdump` will nicely truncate all the blank space for us.
  */
  } =0
}
