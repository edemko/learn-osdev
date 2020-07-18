OUTPUT_FORMAT(binary)

SECTIONS {
  /* Quble will load to this address */
  . = 0x7E00;

  .bootloader : {
    /* the bootloader entry point */
    *(.entry);

    /* text and data sections from regular code */
    *(.text);
    *(.data);

    /* align end of file to a sector boundary */
    . = (. + 511) & (~ 511);
  } =0
}
