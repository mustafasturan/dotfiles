#!/bin/bash

# Read current brightness and max brightness
current_brightness=$(cat /sys/class/backlight/*/brightness)
max_brightness=$(cat /sys/class/backlight/*/max_brightness)

# Calculate brightness percentage
brightness_percent=$(( (current_brightness * 100) / max_brightness ))

# Send dunst notification
dunstify -h int:value:"$brightness_percent" -i ~/.config/dunst/assets/brightness.svg -t 500 -r 2593 "Brightness: ${brightness_percent}%"
