#!/bin/bash
set -e

# WARNING using `../{include,src}` only works because I know that all the object files are produced in one place

includeDir=../include
srcFile=../src/$2.s

zedo ifchange "$srcFile"

gcc -I "$includeDir" -c -o /dev/fd/1 "$srcFile"

# FIXME depend on included files
