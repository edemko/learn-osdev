#!/bin/bash
set -e

# This creates a boot sector from a ELF object file created by the
# sister script `hello-os/build/bootloader-x86_64-bios/default.o.do`.

# The GNU Linker uses a special linker script syntax which is unique to the GNU ecosystem (╯°□°）╯︵ ┻━┻
# Well, what it can accomplish is actually pretty nifty.
# Anyway, we'll need this filepath a couple of times, and I don't feel like writing it out more than once.
ldScript=/hello-os/src/bootloader-x86_64-bios/bootsector.ld

# Our dependencies are an object file and the linker script.
zedo ifchange "$2.o" # The object file is in the same directory as this bootsector
zedo ifchange "$ldScript"

# Then, we instruct the GNU Linker to interpret the script (-T argument) with input from our object file.
# In zedo, the contents of the output file should be written to stdout (here spelled `/dev/fd/1`, which is decently widespread [^1]).
ld -T "$ZTOP/$ldScript" -o /dev/fd/1 "$2.o"
chmod -x /dev/fd/1

# REFERENCES
# [1]: https://unix.stackexchange.com/a/123659
