#!/bin/bash

SERVICE_FILE="sensory_board.service"
SYSTEMD_DIR="/etc/systemd/system"

if [ "$(id -u)" -ne 0 ]; then
	echo "This script must be run as root" 1>&2
	exit 1
fi

cp "$SERVICE_FILE" "$SYSTEMD_DIR"
systemctl daemon-reload
systemctl enable "$SERVICE_FILE"
systemctl start "$SERVICE_FILE"

echo "Service '$SERVICE_FILE' has been added and started succesfully."
