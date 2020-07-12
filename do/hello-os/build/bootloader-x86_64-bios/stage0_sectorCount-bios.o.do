#!/bin/bash
set -e

# TODO document me

zedo ifchange stage1-bios.bin
sectorCount=$(( "$(stat -c"%s" stage1-bios.bin)" / 512 ))
echo >&3 "$sectorCount"

src="$(echo "$1" | sed 's+/build/+/src/+')/stage0_sectorCount-bios.s.in"
zedo ifchange "/$src"

as -o /dev/fd/1 <(sed <"$ZTOP/$src" "s/+REPLACE ME+/$sectorCount/")
