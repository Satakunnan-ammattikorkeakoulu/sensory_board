#!/usr/bin/env bash
set -euo pipefail

# Detect block devices that are likely USB sticks (non-root, removable)
# This uses lsblk and filters out the root device and loop devices.
mapfile -t usb_devices < <(
  lsblk -o NAME,TYPE,RM,TRAN,MOUNTPOINT -nr |
    awk '$2=="disk" && $3==1 {print $1}'
)

if [ "${#usb_devices[@]}" -eq 0 ]; then
  echo "Error: No USB sticks detected." >&2
  exit 1
fi

if [ "${#usb_devices[@]}" -gt 1 ]; then
  echo "Error: Multiple USB sticks detected (${usb_devices[*]}). Please attach only one and try again." >&2
  exit 1
fi

device="${usb_devices[0]}"

# Find the first partition on that device (e.g. sda1, sdb1)
partition=$(lsblk -o NAME,TYPE -nr "/dev/$device" | awk '$2=="part"{print $1; exit}')

if [ -z "${partition:-}" ]; then
  echo "Error: No partition found on /dev/$device. Create a partition and filesystem first." >&2
  exit 1
fi

# Get the UUID of the partition
uuid=$(blkid -s UUID -o value "/dev/$partition" 2>/dev/null || true)

if [ -z "$uuid" ]; then
  echo "Error: Could not determine UUID for /dev/$partition. Ensure it has a filesystem." >&2
  exit 1
fi

echo "UUID=$uuid  /media/sensoryboard_sounds  auto  nofail,noatime,users,rw,uid=1000,gid=1000  0 0"
