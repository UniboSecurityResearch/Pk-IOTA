#! /bin/bash
for i in {1..1000}
do
    sleep 2
    python3 '3_sender_mqtt_nosign.py' cert.txt
done