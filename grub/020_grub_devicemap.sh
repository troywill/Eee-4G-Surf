#!/bin/bash
set -o errexit
grub-mkdevicemap --device-map=device.map
cat device.map
