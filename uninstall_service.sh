#!/usr/bin/env bash
set -euo pipefail

SERVICE_NAME="sensory_board.service"
SERVICE_PATH="/etc/systemd/system/${SERVICE_NAME}"

if [[ "$(id -u)" -ne 0 ]]; then
  echo "This script must be run as root (use: sudo $0)" >&2
  exit 1
fi

echo "Stopping ${SERVICE_NAME} (if running)..."
if systemctl is-active --quiet "${SERVICE_NAME}"; then
  systemctl stop "${SERVICE_NAME}"
else
  echo "Service ${SERVICE_NAME} is not active."
fi

echo "Disabling ${SERVICE_NAME} (if enabled)..."
if systemctl is-enabled --quiet "${SERVICE_NAME}"; then
  systemctl disable "${SERVICE_NAME}"
else
  echo "Service ${SERVICE_NAME} is not enabled."
fi

if [[ -f "${SERVICE_PATH}" ]]; then
  echo "Removing service file ${SERVICE_PATH}..."
  rm -f "${SERVICE_PATH}"
else
  echo "Service file ${SERVICE_PATH} does not exist, nothing to remove."
fi

echo "Reloading systemd daemon..."
systemctl daemon-reload

echo "Service ${SERVICE_NAME} uninstalled successfully."
