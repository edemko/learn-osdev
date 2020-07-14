#!/bin/bash
set -e

# TODO document me

zedo ifchange "$2.stage0" "$2.stage1"

cat "$2.stage0" "$2.stage1"
