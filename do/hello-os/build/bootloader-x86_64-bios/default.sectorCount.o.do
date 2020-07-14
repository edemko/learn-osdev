#!/bin/bash
set -e

# TODO document vis-a-vis the disk partition table

# This build script creates an object file from a templated assembly file.
# In this case, the only place where actual code needs to be replaced is a single number.
# Since it's such a straightforward operation, I've used a strategy that cuts down on the number of build scripts I need.

# The first thing we need to know is how big the stage1 bootloader is going to be.
# We recklessly assume that it's going to be a multipe of 512 bytes,
# but this should ensured by the stage1 linker script `TODO.ld`.
zedo ifchange $2.stage1
sectorCount=$(( "$(stat -c"%s" $2.stage1)" / 512 ))
# The stage0 bootloader makes some assumptions when it loads the stage1,
# so there are some limitations on the size of the stage1 bootloader,
# which we check for now.
if [ "$sectorCount" -gt 254 ]; then
    echo >&2 "Stage 1 bootloader too big to load in a single BIOS disk operation: max size is 254 sectors (127KiB)"
    exit 1
fi
if [ "$sectorCount" -gt 64 ]; then
    echo >&2 "Stage 1 bootloader too big to fit in addresses 0x8000-0xFFFF: max size is 64 sectors (32KiB)"
    exit 1
fi

# I just don't want to have to type this out twice.
src="$(echo "$1" | sed 's+/build/+/src/+')/sectorCount.s.in"

zedo ifchange "/$src"
# Here we use process substitution so that can bass the "filename" of the output of a command.
# This avoids an intermediate file hanging around.
# The process itself is just a simple sed script that looks for `+REPLACE ME+` and turns that into the sector count.
as -o /dev/fd/1 <(sed <"$ZTOP/$src" "s/+REPLACE ME+/$sectorCount/")

# Normally, I'd generate an intermediate file so I can see the result of substituting in the template.
# (Also, normally I'd use `m4` or similar.)
# Here though, the substitution is intentionally very simple, so I'm confident that I will understand what's going on without having to check on the generated assembly.
