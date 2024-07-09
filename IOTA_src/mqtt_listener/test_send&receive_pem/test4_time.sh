#! /bin/bash
for i in {1..200}
do
    echo "$i"
    python3 '2_listener_pem.py' "$i"
    sleep 1
done
