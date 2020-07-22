# This is a stage zero bootloader for Nostalgios.
# It is a compliant with the Quble standard described in `docs/nostalgios/interfaces/quble.md`.

.include "qubleinfo.h"
.include "nos-quble.h"

.intel_syntax noprefix


.section .entry
.code16

_start:
  # canonicalize the `cs:ip` instruction pointer
  jmp 0:bootloader.canonPoint
  bootloader.canonPoint:

  # setup flags as required by Quble
  # nos-quble will not clobber these
  cld # direction = forward
  sti # interrupts enabled

  # save the `dl` register to reduce register pressure in calling conventions
  mov [quble.diskno], dl

  # setup the Quble-required stack
  mov ax, 0x8000
  mov ss, ax
  xor ax, ax
  mov sp, ax

  # setup segment registers as required by Quble
  # (nos-quble will not clobber segment registers)
  mov ds, ax
  mov es, ax


  # Initialize video mode and clear screen
  call quble.initVideo

  mov si, OFFSET msg.hello
  call quble.message

  # Load next stage from disk
  mov si, OFFSET msg.diskload
  call quble.message
  call quble.load
  jnc load.ok
  # Error handler
  mov si, OFFSET msg.diskload.err
  call quble.message
  jmp die
  load.ok:

  # TODO check variant

  mov si, OFFSET msg.checksum.skip
  call quble.message
  # TODO checksum

  mov si, OFFSET msg.goodbye
  call quble.message

  # clear screen and jump to next stage
  call quble.initVideo
  jmp 0:0x7E00

  die:
  jmp quble.halt


.section .data

msg.hello: .asciz "Quble says hello!"

msg.diskload: .asciz "Loading next stage..."
msg.diskload.err: .asciz "Loading failed."

msg.unknownVariant:
  .ascii "Unexpected variant code "
  msg.unknownVariant.code:
  .asciz "00"

msg.checksum: .asciz "Verifying checksum..."
msg.checksum.skip: .asciz "Skipping integrity check."
msg.checksum.err: .asciz "Checksum does not match."

msg.goodbye: .asciz "Exiting Quble..."
