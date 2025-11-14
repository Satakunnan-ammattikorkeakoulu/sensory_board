#!/home/project/sensory_board/venv/bin/python

import RPi.GPIO as GPIO
import vlc
import time
import json

# Global variable to track the last time a sensor was triggered
last_triggered_time = 0

def setup_gpio_pins(sensor_pins, led_pin):
    GPIO.setmode(GPIO.BCM)
    for pin in sensor_pins.values():
        GPIO.setup(pin["gpio"], GPIO.IN, pull_up_down=GPIO.PUD_DOWN)
    GPIO.setup(led_pin, GPIO.OUT)

def reduce_volume(player, reduction_duration):
    current_volume = player.audio_get_volume()
    steps = 10
    step_duration = reduction_duration / steps
    volume_step = current_volume / steps

    for _ in range(steps):
        current_volume -= volume_step
        if current_volume < 0:
            current_volume = 0
        player.audio_set_volume(int(current_volume))
        time.sleep(step_duration)
    
    player.stop()

def check_sensors(sensor_pins):
    missing_sensors = []
    for pin_config in sensor_pins.values():
        sensor_pin = pin_config["gpio"]
        try:
            GPIO.setup(sensor_pin, GPIO.IN, pull_up_down=GPIO.PUD_DOWN)
            GPIO.input(sensor_pin)  # Attempt to read the pin
        except RuntimeError:
            missing_sensors.append(sensor_pin)
    return missing_sensors

def blink_led(led_pin, duration=5):
    end_time = time.time() + duration
    while time.time() < end_time:
        GPIO.output(led_pin, GPIO.HIGH)
        time.sleep(0.5)
        GPIO.output(led_pin, GPIO.LOW)
        time.sleep(0.5)
        print("Sensor missing!")

def main(config_file):
    global last_triggered_time  # Declare last_triggered_time as global

    with open(config_file, 'r') as f:
        config = json.load(f)

    led_pin = config.get("led_pin", 18)  # Default to GPIO 18 if not specified
    setup_gpio_pins(config["pins"], led_pin)

    missing_sensors = check_sensors(config["pins"])
    if missing_sensors:
        print(f"Missing or inaccessible sensors: {missing_sensors}")
        blink_led(led_pin)
        GPIO.cleanup()
        return

    vlc_instance = vlc.Instance('--no-xlib')
    player = vlc_instance.media_player_new()

    try:
        while True:
            # Check each configured pin
            for pin_config in config["pins"].values():
                sensor_pin = pin_config["gpio"]
                mp3_file_path = pin_config["audio_file"]
                timeout_duration = config["timeout_duration"]
                volume_reduction_duration = config["volume_reduction_duration"]

                input_state = GPIO.input(sensor_pin)

                if input_state:
                    print(f"Triggered (GPIO {sensor_pin})")

                    # Update last triggered time
                    last_triggered_time = time.time()

                    # If the player is not already playing, load media file and play
                    if not player.is_playing():
                        media = vlc_instance.media_new(mp3_file_path)
                        player.set_media(media)
                        player.play()

                    # Reset volume to maximum
                    player.audio_set_volume(100)
                elif player.is_playing():
                    # Reset volume to maximum if sensor is triggered while playing
                    player.audio_set_volume(100)

            # Check if it's time to reduce the volume
            if player.is_playing() and time.time() - last_triggered_time > timeout_duration:
                reduce_volume(player, volume_reduction_duration)
                
            # Sleep briefly to avoid high CPU usage
            time.sleep(0.1)

    except KeyboardInterrupt:
        pass
    finally:
        GPIO.cleanup()

if __name__ == "__main__":
    config_file = "config.json"
    main(config_file)
