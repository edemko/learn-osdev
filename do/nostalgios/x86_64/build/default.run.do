#!/bin/bash
set -e

zedo phony
zedo ifchange "$2"
qemu-system-x86_64 -drive file=$2,format=raw # TODO discover the architecture
