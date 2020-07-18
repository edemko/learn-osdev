#!/bin/bash
set -e

ldScript=../bootsector.ld
objFiles="stage0.o nos-quble.o qubleinfo.o"

zedo ifchange "$ldScript" $objFiles

ld -T "$ldScript" -o /dev/fd/1 $objFiles
