#!/bin/bash

sleep 0.4;

while true; do
    ps -A -o comm,pcpu  | grep ffmpeg | grep -v grep | awk '{print $2}' | tee -a $1.log > /dev/null 2>&1
    sleep 0.1;
done