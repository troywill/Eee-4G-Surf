#!/bin/bash
OUTPUT_FILE='/tmp/mbr.sda.safety'
# Safety first: make a copy of mbr
dd bs=512 count=1 if=/dev/sda of=${OUTPUT_FILE}

# Make another copy of mbr
cp --backup ${OUTPUT_FILE} ~

grub-install /dev/sda
