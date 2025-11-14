#!/usr/bin/env bash
set -euo pipefail

# Configuration
SERVICE_NAME="sensory_board.service"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="${PROJECT_DIR}/venv"
PYTHON_BIN="${VENV_DIR}/bin/python"
SERVICE_PATH="/etc/systemd/system/${SERVICE_NAME}"

# Detect user and group that should run the service (non-root user invoking sudo)
RUN_USER="${SUDO_USER:-$(whoami)}"
RUN_GROUP="$(id -gn "${RUN_USER}")"
RUN_UID="$(id -u "${RUN_USER}")"

echo "Installing Sensory Board service"
echo "Project directory: ${PROJECT_DIR}"
echo "Service will run as: ${RUN_USER}:${RUN_GROUP}"

# Ensure running with sudo/root for systemd install
if [[ "$EUID" -ne 0 ]]; then
  echo "This script must be run as root (use: sudo $0)" >&2
  exit 1
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
