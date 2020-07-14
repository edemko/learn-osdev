#!/bin/bash
set -e

# TODO document me

ldScript=/hello-os/src/bootloader-x86_64-bios/stage1.ld

zedo ifchange "$ldScript" "$2.o"

ld -T "$ZTOP/$ldScript" -o /dev/fd/1 "$2.o"
chmod -x /dev/fd/1
