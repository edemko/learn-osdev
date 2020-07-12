#!/bin/bash
set -e

# TODO document me

objFiles=stage0-bios.o
ldScript=/hello-os/src/bootloader-x86_64-bios/mbr.ld

zedo ifchange stage0-bios.mbr stage1-bios.bin

cat stage0-bios.mbr stage1-bios.bin
