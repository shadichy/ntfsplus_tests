#!/bin/bash

if [ $EUID != 0 ]; then
  echo "Please run as root"
  exit 1
fi

mkdir -p tmp
cd tmp

[ -f .env ] || cat <<EOF >.env
KERNEL_LIST=()
MODVERSION=
EOF

nano .env

exec ../run_test.sh
