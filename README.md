# Sensory Board

Start by running the main.py 

```bash
./main.py
```

It should not need venv to be activated, since the shebang points to the correct python environment.

To make it auto run at startup, run
```bash
sudo ./install_service.sh
```

To disable auto run at startup, run
```bash
sudo ./uninstall_service.sh
```

If you change the source code or the config you need to restart the service
```bash
sudo systemctl restart sensory_board.service
```

---

## Config

Config file containing the paths to audio files is `config.json`

### Pins to pads layout

| ------- | ------- | ------- |
| GPIO 4  | GPIO 13 | GPIO 17 |
| ------- | ------- | ------- |
| GPIO 19 | GPIO 26 | GPIO 27 |
| ------- | ------- | ------- |

## TODO:

- Fix shebang
  - Probably need to replace this with a startup script that goes to the
    service file
- Create install script
  - Creates venv
  - Installs dependencies
  - Installs service
