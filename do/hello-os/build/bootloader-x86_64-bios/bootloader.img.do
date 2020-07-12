#!/bin/bash
set -e

# TODO probably turn this into `default.bin.do` and `*.img.do` scripts

objFiles=stage0.o
ldScript=/hello-os/src/bootloader-x86_64-bios/mbr.ld

zedo ifchange stage0.mbr stage1.bin

cat stage0.mbr stage1.bin
