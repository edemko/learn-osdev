#!/bin/bash
set -e

# This generates an ELF object file from an assembly file.
# What this means is that the human-readable assembly file is translated into binary machine code.
# This Machine code is then packaged in an object file format which provides a bunch of metadata and linker information.
# Linking happens in a second stage.

# if the target is `hello-os/build/.../foo.o`,
# the source file is `hello-os/src/.../foo.s`
# This computes the source directory.

src="$(echo "$1" | sed 's+/build/+/src/+')"

# Register the dependency on the source file.
zedo ifchange "/$src/$2.s"

# Use the GNU Assembler `as`.
# I've got no configuration going on here.
# Zedo requires output on stdout, which can be referenced by `/dev/fd/1` on most(?) *nixes
as -o /dev/fd/1 "$ZTOP/$src/$2.s"
