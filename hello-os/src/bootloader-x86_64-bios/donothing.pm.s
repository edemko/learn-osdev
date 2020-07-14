# TODO document me


.intel_syntax noprefix

.section .text
.code32

.global stage1
stage1:

halt:
  cli
  hlt
  jmp halt
