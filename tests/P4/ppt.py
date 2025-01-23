import re
import seaborn as sns
import matplotlib.pyplot as plt
import numpy as np

# Function to read values from a file
def read_values(file_path):
    with open(file_path, 'r') as file:
        content = file.read()
    pattern = r'packet_processing_time_array= ([\d, ]+)'
    match = re.search(pattern, content)
    if match:
        values_str = match.group(1)
        return [int(x) for x in values_str.split(', ')]  # Divide by 1000 to convert to milliseconds
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

# Create a list with the average values
avg = [avg_nosw_value, avg_sw_value]
# Create a list with the standard deviation values
std = [np.std(nosw_values), np.std(sw_values)]

# Create a list with the x string values
x_val = ['Normal', 'Certificate\nvalidation']

sns.set_style("whitegrid")
sns.set_palette("tab10")
sns.set_context("notebook")

# Create a bar plot
#ax = plt.bar(x_val, avg, color='tab:blue', yerr=std, ecolor='red', capsize=5, width=0.5)
sns.barplot(x=x_val, y=avg, palette="bright", hue=x_val, legend=False, width=0.4)

# Add error bars
plt.errorbar(x_val, avg, yerr=std, fmt='o', markersize=4, color='red', mfc='white', zorder=1, ecolor='red', capsize=5)

plt.xticks([0.5,1], x_val, fontsize=16)
plt.xlim(-0.5,1.5)
plt.gca().set_xticks([])
plt.xlabel('')

# Add y values labels
plt.ylabel("Avg Time (" + u"\u03bcs)", fontsize=16)

plt.text(0 + 0.05, avg[0], f"{avg[0]:.2f}", ha='left', va='bottom', fontsize=12)
plt.text(1 + 0.05, avg[1], f"{avg[1]:.2f}", ha='left', va='bottom', fontsize=12)
#plt.text(2 + 0.055, avg[2], f"{avg[2]:.2f}", ha='left', va='bottom', fontsize=16)

# Put right and top margin to 0.95
plt.subplots_adjust(right=0.99, top=0.95, left=0.25, bottom=0.05)

# Modify the dimension of the plot window
fig = plt.gcf()
fig.set_size_inches(4.5, 4)

# plt.xticks(fontsize=18)  # Set dimension of the numbers on the x axis to 18
plt.yticks(fontsize=16)  # Set dimension of the numbers on the y axis to 18

# Show the plot
plt.show()


######## Code for old line plot ########

# # Set the plot style
# sns.set(style="whitegrid")

# # Create the plot
# plt.figure(figsize=(13, 8))

# # Plot both lines
# sns.lineplot(x=range(len(sw_values)), y=sw_values, marker='o', label='OPN with certificate validation', color='orange')
# sns.lineplot(x=range(len(nosw_values)), y=nosw_values, marker='o', label='OPN requests/responses', color='blue')

# # Plot the average lines
# plt.axhline(y=avg_sw_value, color='orange', linestyle='dashdot', label=f'Avg certificate validation = {avg_sw_value:.2f}')
# plt.axhline(y=avg_nosw_value, color='blue', linestyle='dashdot', label=f'Avg without cert. validation = {avg_nosw_value:.2f}')

# # reduce border size white space
# plt.subplots_adjust(left=0.1, right=0.99, top=0.95, bottom=0.1)

# # Customize plot labels and title
# plt.title('Packet Processing Time Comparison', fontsize=20, fontweight='bold')
# plt.xlabel('Packet number', fontsize=18)
# plt.ylabel("Processing Time (" + u"\u03bcs)", fontsize=18)

# # Increase the font size of the x and y labels
# plt.xticks(fontsize=18)
# plt.yticks(fontsize=18)

# # Increase the font size of the legend
# plt.legend(fontsize=18)

# # Save the plot as a pdf file named 'ppt.pdf'
# plt.savefig('ppt.pdf')

# # Show the plot
# plt.show()
