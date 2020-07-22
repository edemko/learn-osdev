#!/bin/bash
set -e

# WARNING using `../{include,src}` only works because I know that all the object files are produced in one place

includeBios=../../../../include # nostalgios/x86_64/include
includeQuble=../include # nostalgios/x86_64/bios/quble/include
srcFile=../src/$2.s

zedo ifchange "$srcFile"

gcc -ffreestanding -I "$includeBios" -I "$includeQuble" -c -o /dev/fd/1 "$srcFile"

# FIXME depend on included files
