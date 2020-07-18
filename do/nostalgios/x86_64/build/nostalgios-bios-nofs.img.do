#!/bin/bash
set -e

# This creates a Nostalgios image with no initial filesystem.
# The stage-zero and -one bootloaders are simply placed consecutively at the start of the image.
# It is intended only for testing the bootloader.

bootDir="../bios/bootloader/build/"
stage0="$bootDir/stage0-quble.bin"
stage1="$bootDir/stage1-quble.bin"

zedo ifchange "$stage0" "$stage1"
cat "$stage0" "$stage1"
