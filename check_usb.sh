#!/usr/bin/env bash
set -euo pipefail

echo "=== USB storage devices currently attached ==="
echo

# Find all currently attached disks whose transport is USB
usb_disks=$(lsblk -S -o NAME,TRAN,TYPE -nr | awk '$2 == "usb" && $3 == "disk" {print $1}')

if [[ -z "${usb_disks}" ]]; then
    echo "No USB disks detected."
    exit 0
fi

for disk in $usb_disks; do
    # List partitions for this USB disk
    parts=$(lsblk -nr -o NAME,TYPE "/dev/${disk}" | awk '$2 == "part" {print $1}')

    if [[ -z "${parts}" ]]; then
        echo "Disk /dev/${disk} has no partitions."
        echo
        continue
    fi

    for part in $parts; do
        dev="/dev/${part}"

        # Get UUID, LABEL, and FSTYPE directly from lsblk (kernel view)
        read UUID LABEL FSTYPE < <(lsblk -nr -o UUID,LABEL,FSTYPE "${dev}")

        echo "Device: ${dev}"
        echo "  UUID:  ${UUID:-<none>}"
#        echo "  Label: ${LABEL:-<none>}"       # This fails when the device has no label.
#        echo "  Type:  ${FSTYPE:-<unknown>}"   # And the previous affects this.
        echo
    done
done


