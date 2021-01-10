#!/bin/bash

while true; do
    ps -A -o comm,pcpu  | grep $2 | grep -v grep | awk '{print $2}' | tee -a $1.log > /dev/null 2>&1
    sleep 0.1;
done