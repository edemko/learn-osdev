#!/bin/bash
set -e

ldScript="../quble/bootloader.ld"
objFiles="../quble/build/stage1.o ../quble/build/stage1text.o" # TODO more?

zedo ifchange "$ldScript" $objFiles
ld -T "$ldScript" -o /dev/fd/1 $objFiles
chmod -x /dev/fd/1
