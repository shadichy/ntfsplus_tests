#!/bin/bash
set -e

SRCDIR=$(dirname "$0")

source "${SRCDIR}/config.sh"
source "${SRCDIR}/compile.sh"

# For each kernel
for kernel in "${KERNEL_LIST[@]}"; do
    # Create qcow2 image
    echo "Creating QEMU image"
    image=testimage-${kernel}.${QEMU_IMG_FORMAT}
    qemu-img create -f "$QEMU_IMG_FORMAT" "$image" "$QEMU_DISK_SIZE"

    # Run QEMU VM
    echo "Running QEMU VM"
    qemu-system-x86_64 \
        -m 256 \
        -enable-kvm \
        -cpu host \
        -smp 1 \
        -kernel "vmlinuz-${kernel}" \
        -initrd "initramfs-${kernel}.img" \
        -drive "if=${QEMU_DISK_CONTROLLER},id=${DISK},file=${image},cache=none,format=${QEMU_IMG_FORMAT}" \
        -append "console=ttyS0" \
        -nographic 2>&1 | tee "log-${kernel}.txt"
done
