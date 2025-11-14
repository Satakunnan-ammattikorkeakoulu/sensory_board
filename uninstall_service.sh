#!/bin/bash

SERVICE_NAME="sensory_board.service"

if [ "$(id -u)" -ne 0 ]; then
	echo "This script must be run as root" 1>&2
	exit 1
fi

systemctl stop "$SERVICE_NAME"
systemctl disable "$SERVICE_NAME"
systemctl daemon-reload
rm "/etc/systemd/system/$SERVICE_NAME"

echo "Service $SERVICE_NAME uninstalled succesfully."
