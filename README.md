# Sensory Board

A Raspberry Pi–based sensory board that plays audio when GPIO-connected pads are triggered.

---

## Supported Devices

- **Hardware**
  - Raspberry Pi with a 40‑pin GPIO header, for example:
    - Raspberry Pi 2 / 3 / 4 / 5
    - Raspberry Pi Zero / Zero 2 W
  - Speakers or headphones connected to the Pi’s audio output.
  - GPIO pins wired as defined in `config.json` (default layout below).

- **Operating System**
  - Raspberry Pi OS (or compatible Linux) with:
    - `systemd` (for running as a service)
    - `python3` and `python3-venv`

This project is **not** intended for non‑Raspberry Pi boards, because it uses `RPi.GPIO`.

---

## Requirements

- **System packages**

  Make sure these are installed:

  ```bash
  sudo apt-get update
  sudo apt-get install -y python3 python3-venv vlc python3-vlc
  ```

- **Project files**

  - `main.py`
  - `config.json`
  - `install_service.sh`
  - `uninstall_service.sh`
  - `requirements.txt`
  - Audio files in `/media/sensoryboard_sounds/current/1.mp3` … `6.mp3` (or as configured in `config.json`).

- **Permissions**

  - You must run `install_service.sh` with `sudo` so it can:
    - Create the virtual environment.
    - Install Python dependencies.
    - Create and enable the `sensory_board.service` systemd unit.
  - The service user (the non‑root user who runs `sudo ./install_service.sh`) must:
    - Have access to GPIO (often via the `gpio` group, or by running the service as root).
    - Have access to the audio device.

---

## Installation

### 1. Clone or copy the project

Place the project on your Raspberry Pi, for example:

```bash
cd /home/pi
git clone <your-repo-url> sensory_board
cd sensory_board
```

Or copy the files into a directory on the Pi, e.g. `/home/pi/sensory_board`.

### 2. Make scripts executable

```bash
chmod +x main.py install_service.sh uninstall_service.sh
```

### 3. Install system dependencies

If you haven’t already:

```bash
sudo apt-get update
sudo apt-get install -y python3 python3-venv vlc python3-vlc
```

### 4. Install and enable the systemd service

Run the install script as the user you want the service to run as (typically `pi`), using `sudo`:

```bash
sudo ./install_service.sh
```

What this script does:

- Creates a Python virtual environment in `./venv` (if it doesn’t exist).
- Installs Python dependencies from `requirements.txt` into the venv.
- Creates `/etc/systemd/system/sensory_board.service` with:
  - `ExecStart` pointing to the venv’s Python and `main.py`.
  - `WorkingDirectory` set to the project directory.
  - `User` and `Group` set to the non‑root user who invoked `sudo`.
  - Audio‑related environment variables (`PULSE_SERVER`, `XDG_RUNTIME_DIR`, `DISPLAY`).
- Reloads systemd and enables the service at boot.

### 5. Start / stop / check the service

Start the service:

```bash
sudo systemctl start sensory_board.service
```

Check status:

```bash
systemctl status sensory_board.service
```

Stop the service:

```bash
sudo systemctl stop sensory_board.service
```

Disable auto‑start at boot:

```bash
sudo systemctl disable sensory_board.service
```

To completely uninstall the service (and clean up the unit file), run:

```bash
sudo ./uninstall_service.sh
```

---

## Running Manually (Optional)

You normally do **not** need to activate the virtual environment manually, because the systemd service uses the venv’s Python directly.

If you want to run `main.py` manually (for testing or debugging):

```bash
cd /path/to/sensory_board
./venv/bin/python main.py
```

`main.py` uses the `#!/usr/bin/env python3` shebang, so you can also run:

```bash
./main.py
```

as long as the required Python packages are installed in the environment that `python3` points to.

---

## Config

Config file containing the paths to audio files and pin mappings is `config.json`.

### Pins to pads layout

Default GPIO layout (BCM numbering):

| ------- | ------- | ------- |
| GPIO 4  | GPIO 13 | GPIO 17 |
| ------- | ------- | ------- |
| GPIO 19 | GPIO 26 | GPIO 27 |
| ------- | ------- | ------- |

The LED pin is configured via `led_pin` in `config.json` (default: GPIO 18).

---

## Updating the Code or Config

If you change the source code or `config.json` and you are using the systemd service, restart the service to apply changes:

```bash
sudo systemctl restart sensory_board.service
```

If you change Python dependencies, update `requirements.txt` and re-run:

```bash
sudo ./install_service.sh
```

to reinstall dependencies into the virtual environment and refresh the service configuration.
