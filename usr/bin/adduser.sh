#!/bin/bash
set -o errexit
set -o nounset
USER=$1

useradd --create-home $USER
password $USER
