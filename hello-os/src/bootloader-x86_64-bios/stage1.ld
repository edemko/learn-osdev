/* TODO document me */

OUTPUT_FORMAT(binary)

SECTIONS {
  . = 0x7E00;
  .diskparttab : {
    /* TODO add disk partition table */
    BYTE (0); /* force _something_ to output here */
    . = 512;
  } =0

  . = 0x8000;
  .text : {
    *(.text);
    *(.data);

    . = (. + 511) & (~ 511); /* align to sector */
  } =0
}
