# Workflow for the testsuite

## Project info

Driver identifier: `ntfsplus`
Language: `bash`
- Linting: `shellcheck`

## Preparation

Environment:
- Kernel resource path: `KRES=/usr/lib/modules/`
- Kernel binary: `KBIN=${KRES}/<kernelN>/vmlinu[xz]`
- Kernel patching command: `dkms install --no-depmod -m <driver identifier>/<modver> -k <kernelN>`
- Mkinicpio config file: `MKINITCPIO_CONF=$(pwd)/initramfs/mkinitcpio.conf`
- Mkinitcpio hook directory: `MKINITCPIO_HOOKDIR=$(pwd)/initramfs/`
- Mkinitcpio command: `mkinitcpio -c ${MKINITCPIO_CONF} -D ${MKINITCPIO_HOOKDIR} -k <kernelN> -g $(pwd)/initramfs-<kernelN>.img`
- QEMU image default format: `QEMU_IMG_FORMAT=qcow2`
- QEMU default disk controller: `QEMU_DISK_CONTROLLER=virtio-scsi`
- QEMU default disk size: `QEMU_DISK_SIZE=5G`
- Testsuite dir: `TESTSUITE_DIR=$(pwd)/tests`
- Test checksum: `CHECKSUM=sha256sum`

Variables:
- Kernels: `KERNEL_LIST=(<kernel1> <kernel2> <kernel3> ... <kernelN>)`
- Module version: `MODVERSION=<modver>`

Dependencies (assume sastisfied on current host):
- `dkms`
- `ntfsplus-dkms`
- `mkinitcpio`
- `ntfsprogs-plus`
- `bash`
- `parted`
- `dd`
- `sha256sum` or `sha<bits>sum`
- `e2fsprogs`
- `qemu`
- `edk2-ovmf`

## Notes

### DKMS

For custom kernel resource paths and module dkms source path, additional arguments `--kernelsourcedir`, `--dkmstree`, `--sourcetree` and `--installtree` can be added to the patching command.

### mkinitcpio

For custom kernel resource paths, additional arguments `--moduleroot`, `--kernelimage` can be added to the generator command.
Custom mkinitcpio configuration for generating initramfs for module testing via qemu vm.
Additional module `ntfsplus` and some modules for keyboard input needs to be added.
Test files are added to `/tests` of the initramfs.

### QEMU

Direct boot kernel and initramfs.

### Testsuite

Test suite format is in mkinitcpio hook.
Tests are generated.

## Tests

List of tests:

1. Write 1MB file using `dd` from `/dev/random` and generate checksums in `/tmp`
2. Read 1MB file and perform file integrity check
3. Delete 1MB file
4. Write 32MB file using `dd` from `/dev/random` and generate checksums in `/tmp`
5. Read 32MB file and perform file integrity check
6. Delete 32MB file
7. Write 1GB file using `dd` from `/dev/random` and generate checksums in `/tmp`
8. Read 1GB file and perform file integrity check
9. Delete 1GB file
10. Write 4GB file using `dd` from `/dev/random` and generate checksums in `/tmp`
11. Read 4GB file and perform file integrity check
12. Delete 4GB file
13. Create checkpoint (`/logs/checkpoint_13`). Write 1GB file but got interrupted in the middle of the process (sleep then reboot)
14. Resume and mount as read-only
15. Unmount
16. Filesystem fix using `ntfsck`
17. Create checkpoint (`/logs/checkpoint_17`). Write 3 1GB files but interrupted in the middle of the process (sleep then reboot)
18. Resume and fix
19. Reformat with `mkfs.ntfsplus`
20. Write 2GB file using `dd` from `/dev/random` and check for leftover spaces (in bytes)

## Test flow

- Note: each kernels run in parallel

1. Build initramfs
2. For each kernel:
  1. Patch kernel
  2. Copy `vmlinu[xz]` to `./vmlinu[xz]-<kernelN>`
  3. Generate initramfs to `./initramfs-<kernelN>.img`
  4. Create qcow2 image named `testimage-<kernelN>.qcow2`
  5. Run qemu vm with direct boot kernel and initramfs, assign qcow2 image


Test initialization hook flow:

1. Mount `/tmp`
2. Check if `/dev/vda1` exists and is mountable, if not:
  1. Create a GPT partition table on `/dev/vda`
  2. Create `/dev/vda1:100MB:ext4`
  3. Create `/logs` and mount `/dev/vda1` to `/logs`
  4. Create `/dev/vda2` with leftover space
  5. Format `/dev/vda2` with `mkfs.ntfsplus`
  6. Create `/mnt` and mount `/dev/vda2` to `/mnt`, if failed, log into `/logs/init.log`
3. Run actual tests in `/tests`, log to `/logs/tests/<test>.log`, resume from checkpoint (if any)
4. Unmount `/mnt`
5. Show logs and shutdown

- Note: `vda` is just an identifier, based on QEMU controller type to adjust the correct identifier (ex: `virtio` for `vda`, `scsi` for `sda`, etc...)