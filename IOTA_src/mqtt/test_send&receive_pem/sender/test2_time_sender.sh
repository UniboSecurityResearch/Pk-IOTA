#! /bin/bash
for i in {1..200}
do
    echo "$i"
    sleep 1
    python3 '3_sender_pem.py' "$i"
    sleep 1
done
