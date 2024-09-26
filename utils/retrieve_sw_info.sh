#!/bin/bash

echo "packet_processing_time_array: " > ./results.txt
echo "register_read packet_processing_time_array" | simple_switch_CLI >> ./results.txt

echo "" >> ./results.txt
echo "packet_dequeuing_timedelta_array: " >> ./results.txt
echo "register_read packet_dequeuing_timedelta_array" | simple_switch_CLI >> ./results.txt