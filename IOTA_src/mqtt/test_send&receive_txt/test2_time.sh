#! /bin/bash
for i in {101..150}
do
    echo "$i"
    python3 '2_listener_mqtt_timer.py' "$i"
    sleep 1
done
