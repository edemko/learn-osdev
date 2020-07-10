#!/bin/bash
set -e

# This creates a master boot record from a ELF object file created by the sister script `hello-os/build/bootloader/default.o.do`.

# The GNU Linker uses a special linker script syntax which is unique to the GNU ecosystem (╯°□°）╯︵ ┻━┻
# Well, what it can accomplish is actually pretty nifty.
# Anyway, we'll need this filepath a coupel of times, and I don't feel like writing it out more than once.
ldScript=/hello-os/src/bootloader/mbr.ld

# Our dependencies are an object file and the linker script.
zedo ifchange do-nothing.o
zedo ifchange "$ldScript"

# Then, we instruct the GNU Linker to interpret the script (-T argument) with input from our object file.
# In zedo, the contents of the output file should be written to stdout (here spelled `/dev/fd/1`, which is decently widespread [^1]).
ld -T "$ZTOP/$ldScript" -o /dev/fd/1 do-nothing.o

# REFERENCES
# [1]: https://unix.stackexchange.com/a/123659
