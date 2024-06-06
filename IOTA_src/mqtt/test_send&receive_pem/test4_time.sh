#! /bin/bash
for i in {1..400}
do
    echo "$i"
    sleep 2
    python3 '2_listener_pem.py' "$i" &
    sleep 1
    cd './sender'
    python3 '3_sender_pem.py' "$i"
    cd '..'
done
