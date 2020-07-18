.intel_syntax noprefix

.section .quble

.global quble
.global quble.bootchain
.global quble.variant.payload
.global quble.variant.code
.global quble.diskno

# TODO struct definitions for known payloads

quble:
  quble.bootchain:
    .int 0xFFFFFFFF # uninitialized bootchain
  quble.variant.payload:
    .quad 0 # uninitialized
  quble.variant.code:
    .byte 0 # Variant Zero; patch this later if a checksum is desired
  quble.diskno:
    .byte 0xFF # uninitialized
