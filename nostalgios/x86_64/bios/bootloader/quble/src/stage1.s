.intel_syntax noprefix


.section .entry
.code16

_start:

# TODO enter protected mode
# TODO setup interrupt table
# TODO enable A20
# TODO enter long mode

  die:
    cli
    hlt
    jmp die