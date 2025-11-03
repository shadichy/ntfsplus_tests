#!/bin/bash

SRCDIR=$(dirname "$0")

### Default variables
MODULE="ntfsplus"
KRES="/usr/lib/modules/"

MKINITCPIO_HOOKDIR="${SRCDIR}/initramfs/"
MKINITCPIO_CONF="${MKINITCPIO_HOOKDIR}/mkinitcpio.conf"
MKINITCPIO_DEFAULT_HOOKDIR=/usr/lib/initcpio

QEMU_IMG_FORMAT="qcow2"
QEMU_DISK_CONTROLLER="virtio"
QEMU_DISK_SIZE="5G"

TESTSUITE_DIR="${SRCDIR}/tests"
TEST_COUNT=20
CHECKSUM="sha256sum"

### User defined
# for example: KERNEL_LIST=("5.15.0-60-generic")
#              MODVERSION="1.0"
KERNEL_LIST=()
MODVERSION=

source .env
