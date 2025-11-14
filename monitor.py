#!/usr/bin/env python3

"""
This script is not used.
"""

import os
import time
import psutil
import RPi.GPIO as GPIO

# Path to the script you want to monitor
SCRIPT_NAME = "test.py"
LOG_FILE = "/var/log/monitor_process.log"
LED_PIN = 18  # Change to the GPIO pin you connected the LED to

# Setup GPIO
GPIO.setmode(GPIO.BCM)
GPIO.setup(LED_PIN, GPIO.OUT)

def log_message(message):
    with open(LOG_FILE, 'a') as log_file:
        log_file.write(f"{time.strftime('%Y-%m-%d %H:%M:%S')}: {message}\n")

def is_script_running(script_name):
    for proc in psutil.process_iter(['pid', 'name', 'cmdline']):
        try:
            # Check if the process command line matches the script name
            if script_name in proc.info['cmdline']:
                return True
        except (psutil.NoSuchProcess, psutil.AccessDenied, psutil.ZombieProcess):
            pass
    return False

try:
    if is_script_running(SCRIPT_NAME):
        log_message(f"{SCRIPT_NAME} is running.")
        GPIO.output(LED_PIN, GPIO.HIGH)  # LED on
    else:
        log_message(f"{SCRIPT_NAME} is not running.")
        GPIO.output(LED_PIN, GPIO.LOW)   # LED off
        # Blink LED to indicate error
        for _ in range(5):
            GPIO.output(LED_PIN, GPIO.HIGH)
            time.sleep(0.5)
            GPIO.output(LED_PIN, GPIO.LOW)
            time.sleep(0.5)
        # Uncomment the next line if you want to start the process if it's not running
        # os.system("python3 /home/project/esnsory_board/test.py &")
finally:
    GPIO.cleanup()
