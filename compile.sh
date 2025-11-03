#!/bin/bash
set -e

SRCDIR=$(dirname "$0")

source "${SRCDIR}/config.sh"

HOOK_NAME="ntfsplus_test"
HOOK_DIR="${MKINITCPIO_HOOKDIR}"

# Determine disk identifier
part_prefix=""
case "$QEMU_DISK_CONTROLLER" in
virtio*)
    disk="vda"
    module="virtio-scsi"
    ;;
scsi)
    disk="sda"
    module="scsi_mod"
    ;;
ide)
    disk="hda"
    module="" # builtin
    ;;
*)
    echo "Unsupported disk controller $QEMU_DISK_CONTROLLER"
    exit 1
    ;;
esac

part1="${disk}${part_prefix}1"
part2="${disk}${part_prefix}2"

export DISK="${disk}"
export PART_PREFIX="${part_prefix}"

# Compile tests
for test in "${SRCDIR}/tests"/*.in; do
    cat "$test" |
        sed "s|%disk%|${disk}|g" |
        sed "s|%part1%|${part1}|g" |
        sed "s|%part2%|${part2}|g" >"${test%.in}.sh"
done

# Compile the hook
cat "${HOOK_DIR}/hooks/${HOOK_NAME}.in" |
    sed "s|%disk%|${disk}|g" |
    sed "s|%part1%|${part1}|g" |
    sed "s|%part2%|${part2}|g" |
    sed "s|%testcount%|${TEST_COUNT}|g" >"${HOOK_DIR}/hooks/${HOOK_NAME}"

cat "${HOOK_DIR}/install/${HOOK_NAME}.in" |
    sed "s|%checksum%|${CHECKSUM}|g" |
    sed "s|%srcdir%|${SRCDIR}|g" >"${HOOK_DIR}/install/${HOOK_NAME}"

chmod +x "${HOOK_DIR}/"{hooks,install}"/${HOOK_NAME}"

cat "${HOOK_DIR}/mkinitcpio.conf.in" |
    sed "s|%storagemod%|${module}|g" |
    sed "s|%hook%|${HOOK_NAME}|g" >"${MKINITCPIO_CONF}"

# Copy needed hooks
cp "${MKINITCPIO_DEFAULT_HOOKDIR}/hooks/udev" "${MKINITCPIO_HOOKDIR}/hooks/udev"
cp "${MKINITCPIO_DEFAULT_HOOKDIR}/install/udev" "${MKINITCPIO_HOOKDIR}/install/udev"
cp "${MKINITCPIO_DEFAULT_HOOKDIR}/install/base" "${MKINITCPIO_HOOKDIR}/install/base"
cp "${MKINITCPIO_DEFAULT_HOOKDIR}/install/keyboard" "${MKINITCPIO_HOOKDIR}/install/keyboard"

# For each kernel
for kernel in "${KERNEL_LIST[@]}"; do
    KBIN=$(find "${KRES}/${kernel}" -mindepth 1 -maxdepth 1 -type f -iname "vmlinu*" -print -quit)

    # Patch kernel
    echo "Installing ntfsplus-dkms for kernel ${kernel}"
    dkms install --no-depmod -m "ntfsplus/${MODVERSION}" -k "$kernel"

    # Copy vmlinuz
    echo "Copying kernel binary"
    cp "$KBIN" "$(pwd)/vmlinuz-${kernel}"

    # Generate initramfs
    echo "Generating initramfs"
    mkinitcpio -c "$MKINITCPIO_CONF" -D "$MKINITCPIO_HOOKDIR" -k "$kernel" -g "$(pwd)/initramfs-${kernel}.img"
done
