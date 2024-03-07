#! /bin/bash
for i in {1..1000}
do
    echo "$i"
    sleep 2
    python3 '2_listener_der.py' "$i" &
    sleep 1
    cd './sender'
    python3 '3_sender_der.py' "$i"
    cd '..'
done
