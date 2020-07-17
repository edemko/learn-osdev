#!/bin/bash
set -e

# This creates a bootsector containing a BIOS-based stage0 bootloader
# specialized to load the correct number of sectors in the stage1 program.
# The stage1 bootloader can be in 16-bit real mode, 32-bit protected mode, or 64-bit long mode,
# and the correct stage0 code will be loaded based on the extension.

# TODO document me

case "$2" in
    *.rm)
        mode=rm
    ;;
    *.pm)
        mode=pm
    ;;
    *.lm)
        mode=lm
    ;;
    *)
        echo >&2 "unknown mode: stage0 can only be built from a .rm.o, .rm.o, or .rm.o"
        exit 1
    ;;
esac

objFiles="stage0.$mode.o $2.sectorCount.o"
ldScript=/hello-os/src/bootloader-x86_64-bios/bootsector.ld


zedo ifchange "$ldScript" $objFiles

ld -T "$ZTOP/$ldScript" -o /dev/fd/1 $objFiles
chmod -x /dev/fd/1
