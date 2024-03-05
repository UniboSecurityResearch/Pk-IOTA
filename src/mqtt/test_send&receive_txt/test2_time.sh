#! /bin/bash
for i in {1000..1300}
do
    echo "$i"
    sleep 2
    python3 '2_listener_mqtt_timer.py' "$i" &
    sleep 1
    cd './sender'
    python3 '3_sender_mqtt_noinput.py' "$i"
    cd '..'
done
