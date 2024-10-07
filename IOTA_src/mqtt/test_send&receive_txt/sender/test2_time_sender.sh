#! /bin/bash
for i in {101..150}
do
    echo "$i"
    sleep 1
    python3 '3_sender_mqtt_noinput.py' "$i"
    sleep 1
done
