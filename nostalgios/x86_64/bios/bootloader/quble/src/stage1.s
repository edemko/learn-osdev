.intel_syntax noprefix

.include "gdt.h"
.include "stage1text.h"

# WARNING that there is no default `.code{16,32,64}` for this file
# that's because we have to move between all three for our entrypoint


.section .data
# These GDT structures must be put a the start of this file because GNU as is single-pass

GDTR.PM gdt32
GDT.PM gdt32
  GDTentry.PM gdt32 code  0       0xFFFFF 0b10011010 1 1
  GDTentry.PM gdt32 data  0       0xFFFFF 0b10010010 1 1
  # by choosing this base and limit, we can get stack protection with `ss = gdt32.stack.offset`
  # I've chosen expand-up because the stack segment is not meant to grow,
  # and also I'm lazy and don't want to deal with the base/limit having backward semantics
  GDTentry.PM gdt32 stack 0x80000 0x0FFFF 0b10010010 0 1
GDTend.PM gdt32


.section .entry
_start:
  .code16

  # Use BIOS to disable the cursor, since there's no interaction at this point
  mov ah, 0x01 # BIOS function = set cursor shape
  mov ch, 0x10 # set cursor disabled bit
  int 0x10     # call BIOS video function

  # Print message about entering protected mode
  mov si, OFFSET msg.protected.enter
  call printLn16

  # Initialize GDT register (see `.data` section below for the GDT we use)
  lgdt [gdt32.r]

  # Enter Protected Mode
  cli
  mov eax, cr0
  or eax, 0x1 # set the protected mode bit (bit 0 of cr0)
  mov cr0, eax
  jmp gdt32.code.offset:protected.entry # initialize `cs` register before a GP fault happens
  protected.entry:
  .code32

  # Initialize segment selectors
  mov eax, gdt32.data.offset
  mov ds, ax
  mov es, ax
  mov fs, ax
  mov gs, ax
  # also re-initialize stack (not changing the location or contents, just fixing up memory segmentation)
  mov eax, gdt32.stack.offset
  mov ss, ax
  mov esp, 0x90000 # address just after the stack

  # Enable A20 line
  mov ax, 0xAA55    # the expected value in 0x7DFE (at the end of the bootsector)
  mov edi, 0x107DFE # the corresponding address in an odd-numbered MiB
  cmp ax, [edi]
  jnz a20.enabled # if they don't match, we know A20 is already enabled
    # Even if they do match, it might just be chance.
    # To make sure it's not already on, let's write to the location and check again.
    rorw [edi], 8 # rotate a word 8 bits, thereby swapping the bytes
    cmp ax, [edi]
    mov [edi], ax # we want to clean up the memory we altered, just in case this sector is written back
    jnz a20.enabled   # if we've forced them to not match, we know A20 is already enabled
  a20.enable:
    # If we've made it here, the A20 line is definitely not enabled.
    mov esi, OFFSET msg.a20.enabling.unimplemented
    call printLn32 # give a little status update
    # QEMU (at least by default) does enable A20 before the bootsector is loaded, so I'm not sure how to test this yet.
    hlt # TODO I need to enable the A20 line
    # TODO check that A20 enabling worked, but die if still not on
  a20.enabled:
  mov esi, OFFSET msg.a20.enabled
  call printLn32 # give a little status update



# TODO enter long mode
  # set up a long-mode GDT
  # initialize page tables
    # certainly at least first 1MiB should be identity-mapped for now
    # higher adress can remain unmapped: the kernel should deal with them
    # this dould be done with:
    #   a level-4 table with one present entry (maps up to 2^9 GiB with 4KiB)
    #   a level 3 table with one present entry (maps up to 1 GiB with 4KiB)
    #   a level-2 table with one present entry (maps up to 2MiB with 4KiB)
    #   a level-1 table filled with identity-mapped entries (maps 2MiB with 4KiB)
    # thereby using 16KiB (max offset +0x3fff) for page tables
    # which is a suprisingly good 99.2% efficiency
    # however, if "huge" 2MiB pages are allowed, then we can skip level-1
    # OTOH, I may be able to use 4KiB paging to get stack protection

  # enable PAE (cr4.pae (bit 5?)) (FIXME use `bts` instr elsewhere as well)
  # load cr3 (start of page table tree)
  # enable long mode (EFER.LME (msr 0x0C000_0080, bit 8))
  # enable paging (cr0.pe (bit 31?)) activates long mode
  # long jump to 64-bit code (loading cs?)
  # initialize stack
  # load 64-bit gdt, maybe with a far jump to re-init cs?
  # reload fs, gs registers
# set up IVT, LDT, TSS and enable interrupts in kernel code if needed
# the kernel _may_ choose to put these descriptors at high addresses, but I don't see why it would matter


# TODO _don't_ try to write these messages to a logfile; the logfiel will only hold messages from the kernel and if we die here, we just leave the messages on-screen

  die:
    cli
    hlt
    jmp die


.section .data

msg.protected.enter: .asciz "Entering protected mode..."
msg.a20.enabled: .asciz "A20 line enabled."
msg.a20.enabling.unimplemented: .asciz "UNIMPLEMENTED: enable A20 line"