#!/bin/bash
set -e

zedo phony

biosboot=hello-os/build/bootloader-x86_64-bios/

zedo \
    $biosboot/{donothing,hello,selfdump}.bootsector \
    $biosboot/{donothing,hello}.rm.img \
    $biosboot/donothing.pm.img \
