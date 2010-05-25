#!/bin/bash
INPUT_DEVICE='/dev/sda'
OUTPUT_FILE='/tmp/mbr.sda.safety'
# Safety first: make a copy of mbr
dd bs=512 count=1 if=${INPUT_DEVICE} of=${OUTPUT_FILE}

# Make another copy of mbr
cp --backup ${OUTPUT_FILE} ~

# grub-install /dev/sda
grub-install /dev/sdb
dd bs=512 count=1 if=${INPUT_DEVICE} of=/root/mbr.after.grub.install
