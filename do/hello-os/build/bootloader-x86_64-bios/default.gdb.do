#!/bin/sh
set -e

zedo phony

zedo $2
qemu-system-x86_64 -S -s -drive file=$2,format=raw
