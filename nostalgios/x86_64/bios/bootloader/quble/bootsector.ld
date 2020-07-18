OUTPUT_FORMAT(binary)

SECTIONS {
  /* BIOS will load to this address */
  . = 0x7C00;

  .bootsector : {
    /* the bootloader entry point, i.e. analogous to the "main" function */
    *(.entry);

    /* text and data sections from library code */
    *(.text);
    *(.data);

    /* the Quble Info Structure */
    . = 496;
    *(.quble);

    /* The bootsector signature */
    . = 510;
    SHORT (0xAA55);
  
  /* Fill empty space with the `hlt` instruction */
  } =0xF4
}
