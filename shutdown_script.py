#!/usr/bin/env python3

import RPi.GPIO as GPIO
import time
import subprocess
from threading import Event

# Define the GPIO pin connected to the button (using BCM numbering)
BUTTON_PIN = 22

def shutdown(channel):
    """Callback function to shutdown the system when the button is pressed."""
    # print("Button pressed! Initiating shutdown...")
    # Execute the shutdown command; this requires sudo privileges
    subprocess.call(['shutdown', '-h', 'now'])

def main():
    # Set up GPIO using BCM numbering
    GPIO.setmode(GPIO.BCM)
    print("Setmode: ok")
    
    # Configure the button pin as an input with an internal pull-up resistor
    GPIO.setup(BUTTON_PIN, GPIO.IN, pull_up_down=GPIO.PUD_UP)
    print("Setup: ok")

    
    # Add an event listener on the falling edge (when the button is pressed)
    # bouncetime is set to 200ms to debounce the button
    GPIO.add_event_detect(BUTTON_PIN, GPIO.FALLING, callback=shutdown, bouncetime=200)
    print("Add event: ok")

    
    # print(f"Listening for button press on GPIO pin {BUTTON_PIN}. Press the button to shutdown.")

    try:
        # Keep the script running
        while True:
            time.sleep(1)
            
    except KeyboardInterrupt:
        print("Exiting program.")
    finally:
        GPIO.cleanup()  # Clean up GPIO settings

if __name__ == '__main__':
    main()

