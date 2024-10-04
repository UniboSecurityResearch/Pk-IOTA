#! /bin/bash
for i in {1..400}
do
    echo "$i"
    python3 '3_sender_pem.py' "$i"
done
