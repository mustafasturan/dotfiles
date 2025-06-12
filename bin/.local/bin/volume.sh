#!/bin/bash

volume=$(pamixer --get-volume)
dunstify -h int:value:"$volume" -i ~/.config/dunst/assets/volume.svg -t 500 -r 2593 "Volume: $volume %"
