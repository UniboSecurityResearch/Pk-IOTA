#!/usr/bin/python3
import numpy as np
import matplotlib.pyplot as plt
import math
import seaborn as sns
import pandas as pd

# Initialize the lists to store the values
conn = []
sw_conn = []

# Specify the path of the file to read
file_path = "./results_conn_no_sw.txt"
with open(file_path, 'r') as file:
    for line in file:
        line = line.strip()  # Remove leading and trailing whitespaces
        if line:
            conn.append(float(line))

file_path = "./results_conn.txt"
with open(file_path, 'r') as file:
    for line in file:
        line = line.strip()
        if line:
            sw_conn.append(float(line))

# Trunc all values to 9 decimal places
factor = 10**9
conn = [math.trunc(element * factor) / factor for element in conn]
conn = [element * 1000 for element in conn]
sw_conn = [math.trunc(element * factor) / factor for element in sw_conn]
sw_conn = [element * 1000 for element in sw_conn]

# Calculate the average
conn_avg = np.mean(conn)
sw_conn_avg = np.mean(sw_conn)


# Print avg values
print("Avg conn: ", conn_avg)
print("Avg vpn_conn: ", sw_conn_avg)

# Calculate the standard deviation
conn_std = np.std(conn)
sw_conn_std = np.std(sw_conn)

# Create a list with the average values
avg = [conn_avg, sw_conn_avg]
# Create a list with the standard deviation values
std = [conn_std, sw_conn_std]

# Create a list with the x string values
x_val = ['Normal', 'Certificate\nvalidation']

sns.set()
sns.set_palette("tab10")
sns.set_context("notebook")

# Create a bar plot
#ax = plt.bar(x_val, avg, color='tab:blue', yerr=std, ecolor='red', capsize=5, width=0.5)
sns.barplot(x=x_val, y=avg, palette="bright", hue=x_val, legend=False, width=0.7)

# Add error bars
plt.errorbar(x_val, avg, yerr=std, fmt='o', markersize=4, color='red', mfc='white', zorder=1, ecolor='red', capsize=5)

# Add y values labels
plt.ylabel('Avg Time (ms)', fontsize=18)

plt.text(0 + 0.05, avg[0], f"{avg[0]:.2f}", ha='left', va='bottom', fontsize=14)
plt.text(1 + 0.05, avg[1], f"{avg[1]:.2f}", ha='left', va='bottom', fontsize=14)
#plt.text(2 + 0.055, avg[2], f"{avg[2]:.2f}", ha='left', va='bottom', fontsize=16)

# Put right and top margin to 0.95
plt.subplots_adjust(right=0.95, top=0.95, left=0.17)

# Modify the values on the y axis, maximum value is 150
plt.ylim(0, 130)

# Modify the dimension of the plot window
fig = plt.gcf()
fig.set_size_inches(6, 6)

plt.xticks(fontsize=18)  # Set dimension of the numbers on the x axis to 18
plt.yticks(fontsize=18)  # Set dimension of the numbers on the y axis to 18

# Add a title to the plot
plt.title('OPC UA Handshake Time', fontsize=20)

# Show the plot
plt.show()