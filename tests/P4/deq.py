import re
import seaborn as sns
import matplotlib.pyplot as plt
import numpy as np

# Function to read values from a file
def read_values(file_path):
    with open(file_path, 'r') as file:
        content = file.read()
    pattern = r'packet_dequeuing_timedelta_array= ([\d, ]+)'
    match = re.search(pattern, content)
    if match:
        values_str = match.group(1)
        return [int(x) for x in values_str.split(', ')]
    else:
        print(f"No matching data found in {file_path}")
        return []

# File paths for the two files
file_path1 = './results_pptdeq_sw.txt'
file_path2 = './results_pptdeq_nosw.txt'

# Read values from both files
sw_values = read_values(file_path1)
nosw_values = read_values(file_path2)

# Calculate averages for both datasets
avg_sw_value = np.mean(sw_values)
avg_nosw_value = np.mean(nosw_values)

# Set the plot style
sns.set(style="whitegrid")

# Create the plot
plt.figure(figsize=(13, 8))

# Plot both lines
sns.lineplot(x=range(len(sw_values)), y=sw_values, marker='o', label='OPN with certificate validation', color='orange')
sns.lineplot(x=range(len(nosw_values)), y=nosw_values, marker='o', label='OPN requests/responses', color='blue')

# Plot the average lines
plt.axhline(y=avg_sw_value, color='orange', linestyle='dashdot', label=f'Avg certificate validation = {avg_sw_value:.2f}')
plt.axhline(y=avg_nosw_value, color='blue', linestyle='dashdot', label=f'Avg without cert. validation = {avg_nosw_value:.2f}')

# reduce border size white space
plt.subplots_adjust(left=0.1, right=0.99, top=0.95, bottom=0.1)

# Customize plot labels and title
plt.title('Packet Dequeuing Time Comparison', fontsize=20, fontweight='bold')
plt.xlabel('Packet number', fontsize=18)
plt.ylabel("Dequeuing Time (" + u"\u03bcs)", fontsize=18)

# Increase the font size of the x and y labels
plt.xticks(fontsize=18)
plt.yticks(fontsize=18)

# Increase the font size of the legend
plt.legend(fontsize=18)

# Save the plot as a pdf file named 'ppt.pdf'
plt.savefig('deq.pdf')


# Show the plot
plt.show()
