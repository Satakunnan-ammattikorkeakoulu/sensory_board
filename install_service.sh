#!/usr/bin/env bash
set -euo pipefail

# Configuration
SERVICE_NAME="sensory_board.service"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="${PROJECT_DIR}/venv"
PYTHON_BIN="${VENV_DIR}/bin/python"
SERVICE_PATH="/etc/systemd/system/${SERVICE_NAME}"
FSTAB_PATH="/etc/fstab"
MOUNT_POINT="/media/sensoryboard_sounds"

# Detect user and group that should run the service (non-root user invoking sudo)
RUN_USER="${SUDO_USER:-$(whoami)}"
RUN_GROUP="$(id -gn "${RUN_USER}")"
RUN_UID="$(id -u "${RUN_USER}")"

usage() {
  cat <<EOF
Usage: sudo $(basename "$0") <UUID>

Install the Sensory Board systemd service and append an fstab entry for the USB stick.

Arguments:
  UUID    The UUID of the USB stick partition to mount at ${MOUNT_POINT}

Example:
  sudo $(basename "$0") 1234-ABCD
EOF
}

if [[ $# -ne 1 ]]; then
  echo "Error: UUID argument is required." >&2
  usage
  exit 1
fi

USB_UUID="$1"

echo "Installing Sensory Board service"
echo "Project directory: ${PROJECT_DIR}"
echo "Service will run as: ${RUN_USER}:${RUN_GROUP}"
echo "Using USB UUID: ${USB_UUID}"

# Ensure running with sudo/root for systemd install and fstab modification
if [[ "$EUID" -ne 0 ]]; then
  echo "This script must be run as root (use: sudo $0 <UUID>)" >&2
  exit 1
fi

# Ensure mount point exists
if [[ ! -d "${MOUNT_POINT}" ]]; then
  echo "Creating mount point directory: ${MOUNT_POINT}"
  mkdir -p "${MOUNT_POINT}"
  chown "${RUN_USER}:${RUN_GROUP}" "${MOUNT_POINT}"
fi

# Append fstab entry if not already present
FSTAB_LINE="UUID=${USB_UUID}  ${MOUNT_POINT}  auto  nofail,noatime,users,rw,uid=1000,gid=1000  0 0"

echo "Configuring /etc/fstab entry..."
if grep -qE "UUID=${USB_UUID}[[:space:]]+${MOUNT_POINT}[[:space:]]" "${FSTAB_PATH}"; then
  echo "An fstab entry for UUID ${USB_UUID} and mount point ${MOUNT_POINT} already exists. Skipping append."
else
  # Also avoid duplicate mount point with different UUIDs
  if grep -qE "[[:space:]]${MOUNT_POINT}[[:space:]]" "${FSTAB_PATH}"; then
    echo "Warning: An existing fstab entry for mount point ${MOUNT_POINT} was found." >&2
    echo "It will NOT be modified automatically. Please review /etc/fstab manually if needed." >&2
  else
    echo "Appending fstab entry:"
    echo "  ${FSTAB_LINE}"
    echo "${FSTAB_LINE}" >> "${FSTAB_PATH}"
  fi
fi

# Create virtual environment if it doesn't exist
if [[ ! -d "${VENV_DIR}" ]]; then
  echo "Creating virtual environment in ${VENV_DIR}..."
  python3 -m venv "${VENV_DIR}"
else
  echo "Virtual environment already exists at ${VENV_DIR}"
fi

# Install Python requirements
if [[ -f "${PROJECT_DIR}/requirements.txt" ]]; then
  echo "Installing Python dependencies from requirements.txt..."
  "${VENV_DIR}/bin/pip" install --upgrade pip
  "${VENV_DIR}/bin/pip" install -r "${PROJECT_DIR}/requirements.txt"
else
  echo "requirements.txt not found in ${PROJECT_DIR}" >&2
  exit 1
fi

# Create systemd service file with proper user, group, ExecStart, and WorkingDirectory
echo "Creating systemd service at ${SERVICE_PATH}..."

cat > "${SERVICE_PATH}" <<EOF
[Unit]
Description=Sensory Board Service
After=sound.target

[Service]
ExecStart=${PYTHON_BIN} ${PROJECT_DIR}/main.py
WorkingDirectory=${PROJECT_DIR}
StandardOutput=journal
StandardError=journal
Restart=always
User=${RUN_USER}
Group=${RUN_GROUP}
Environment=PYTHONBUFFERED=1
Environment=PULSE_SERVER=unix:/run/user/${RUN_UID}/pulse/native
Environment=XDG_RUNTIME_DIR=/run/user/${RUN_UID}
Environment=DISPLAY=:0

[Install]
WantedBy=multi-user.target
EOF

# Set permissions
chmod 644 "${SERVICE_PATH}"

# Reload systemd and enable service
echo "Reloading systemd daemon..."
systemctl daemon-reload

echo "Enabling ${SERVICE_NAME}..."
systemctl enable "${SERVICE_NAME}"

echo "You can start the service with:"
echo "  sudo systemctl start ${SERVICE_NAME}"
echo "Check status with:"
echo "  systemctl status ${SERVICE_NAME}"
