# Macros for creating x86-family Global Descriptor Tables (GDT) as constant memory.
#
# The GDT-defining macros here should follow a prescribed pattern of usage.
# First use `GDT.<mode>`, then zero or more `GDTentry.<mode>` macros (but nothing else), and close it with `GDTend.<mode>`.
# We support protected mode with `PM` and (TODO unimplemented )long mode with `LM`.
#
# ```
# GDT.<mode> <table name>
# GDTentry.<mode> <table name> <entry 1 name> <args...>
# GDTentry.<mode> <table name> <entry 2 name> <args...>
# ...
# GDTend.<mode> <table name>
# ```

# DOCS GDTR.PM gdtname
# Set up data to be loaded into the `gdtr` register for protected mode.
# This macro emits alignment/padding to ensure aligned loads.
# arg `gdtname`: the "GDT name", see `GDT.PM`
# label `${gdtname}.r`: address to be referenced by `lgdt`
.macro GDTR.PM gdtname
  # align start address
  .balign 4
  .fill 2
  \gdtname\().r:
    # size of the GDT
    .hword \gdtname\().end - \gdtname\() - 1
    # start address of the GDT
    .int \gdtname
.endm

# DOCS GDT.PM gdtname
# Set up the start of the GDT, including the required null descriptor at the start.
# This macro emits alignment/padding to ensure aligned loads.
# arg `gdtname`: base name used to create labels and constants related to this GDT
# label `${gdtname}`: start of the GDT
# label `${gdtname}.NULL`: start of the null descriptor
.macro GDT.PM gdtname
  .balign 8
  \gdtname\():
    \gdtname\().NULL: .quad 0
.endm

# DOCS GDTentry.PM gdtname, entryname, base, limit, access, gr, sz
# Emit a GDT descriptor.
# arg 'gdtname`: base name of the GDT this entry belongs to
# arg `entryname`: base name used to create labels and constants related to this entry
# arg `base`: 32-bit base field
# arg `limit`: 20-bit limit field
# arg `access`: access byte. For reference, we repoduce the meaning of the bits here:
#                 * Pr: present bit
#                 * Privil: 2-bit priviledge level (0-3)
#                 * S: descriptor type bit (set for code/data, clear for system)
#                 * Ex: executable bit (set for code segments, clear for data)
#                 * DC: direction/conforming bit
#                       (in code segments: set if execution permitted in a lower priveledge level, clear if not)
#                       (in data segments: set for grows down, clear for grows up)
#                 * RW: readable/writable bit
#                       (in code segments: set if read access allowed; write never allowed)
#                       (in data segments: set if write access allowed; read access always allowed)
#                 * Ac: accessed bit (CPU sets this when the segment is accessed; should probably start clear)
# arg `gr`: granularity bit (if set, multiplies the limit by 4KiB)
# arg `sz`: size bit (0 for 16-bit protected mode, 1 for 32-bit protected mode)
# label `${gdtname}.${entryname}`: start of this GDT entry
# constant `${gdtname}.${entryname}.offset`: offset of this start of this entry from the start of the GDT
.macro GDTentry.PM gdtname, entryname, base, limit, access, gr, sz
  \gdtname\().\entryname\():
  .equ \gdtname\().\entryname\().offset, \gdtname\().\entryname\() - \gdtname\()
    # base bits 0-15
    .hword \limit & 0x0000FFFF
    # limit bits 0-15
    .hword \base & 0x0FFFF
    # base bits 16-23
    .byte  (\base & 0x00FF0000) >> 16
    # access bits
    .byte  \access
    # flags and limit bits 16-19
    .byte  ((\gr & 1) << 7) | ((\sz & 1) << 6) | ((\limit & 0xF0000) >> 16)
    # base bits 24-31
    .byte  (\base & 0xFF000000) >> 24
.endm

# DOCS GDTend.PM gdtname
# Close a GDT definition.
# arg 'gdtname`: base name of the GDT to end
# label `${gdtname}.end`: end of the GDT
.macro GDTend.PM gdtname
  \gdtname\().end:
.endm
