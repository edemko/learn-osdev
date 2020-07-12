#!/bin/bash
set -e

# This creates a master boot record containing a BIOS-based stage0 bootloader.

objFiles="stage0-bios.o stage0_sectorCount-bios.o"
ldScript=/hello-os/src/bootloader-x86_64-bios/mbr.ld

zedo ifchange "$ldScript"
zedo ifchange $objFiles

ld -T "$ZTOP/$ldScript" -o /dev/fd/1 $objFiles
chmod -x /dev/fd/1
