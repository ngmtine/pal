#!/bin/bash

count=1

restart() {
    count=1
    echo "Restarting..."
}

trap 'restart' SIGHUP

while true; do
    echo "Mock main.js is running... $count"
    sleep 1
    ((count++))
done
