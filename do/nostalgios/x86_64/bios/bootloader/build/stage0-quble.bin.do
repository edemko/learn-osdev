#!/bin/bash
set -e

stage0=../quble/build/stage0.bin
stage1=stage1-quble.bin

zedo ifchange $stage0 $stage1

stage1size=$(( "$(stat -c"%s" $stage1)" / 512 ))

if [ "$stage1size" -gt 65 ]; then
    echo >&2 "next stage too big: Quble allows at most 65 sectors (32.5KiB)"
    exit 1
elif [ "$stage1size" -lt 1 ]; then
    echo >&2 "next stage too small: Quble requires at least 1 sectors (512B)"
    exit 1
else
    # Quble uses values 0..64 to mean 1..65
    stage1size=$(( $stage1size - 1 ))
fi


# TODO for now, I'm putting it right after stage0, but
# TODO once I have a filesystem, I should put stage1 into it with the other files

# [use dd to patch binary file](https://stackoverflow.com/a/5586379)
cat ../quble/build/stage0.bin >/dev/fd/1
printf '\x2\x0\x0%b' "\x$stage1size" | dd conv=notrunc bs=1 seek=496 count=4 of=/dev/fd/1
