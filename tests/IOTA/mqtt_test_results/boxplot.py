import seaborn as sns
import matplotlib.pyplot as plt
import pandas as pd
from matplotlib.lines import Line2D  # Import for custom legend lines

sns.set_theme(style="ticks")

# Initialize the figure with a more rectangular shape
f, ax = plt.subplots(figsize=(12, 6))  # Increased width to allow space for "Type" label

# Load the data from the CSV file
data = pd.read_csv("/home/giac/Pk-IOTA/tests/IOTA/mqtt_test_results/mqtt_updated.csv")

# Remove 'Smart Contract' from the 'Type' column for visualization
data["Type"] = data["Type"].str.replace("MQTT", "", regex=False).str.strip()  # Rimuove spazi in eccesso

# Convert 'Time (ms)' from milliseconds to seconds
data["Time (s)"] = data["Time (ms)"] / 1000  # Divide by 1000 to convert ms to s

# Define base colors for each geographical distance
base_palette = {
    "EU-EU": ["#3b7196", "#5b96e3", "#a8c2e3"],   # Blu e celeste
    "EU-AUS": ["#92979c", "#c9c9c9", "#dbcece"],  # Grigio celeste e grigio rosa
    "USA-AUS": ["#de9f9e", "#c75d5f", "#a63f40"]  # Rosso e rosso chiaro
}

# Assign colors to each 'Type' based on its distance category
palette = [base_palette[type_.split()[0]][i % 3] for i, type_ in enumerate(data["Type"].unique())]

# Set border colors and styles for 'txt' and 'pem' formats
border_colors = {
    "txt": ("black", "dashed"),  # Black dashed border for txt formats
    "pem": ("black", "solid"),  # Black solid border for pem formats
    "der": ("black", "dotted")
}

# Plot the boxplots with customized colors and borders
for i, type_ in enumerate(data["Type"].unique()):
    # Determine border color and fill color based on format and distance
    format_type = "txt" if "txt" in type_ else "pem" if "pem" in type_ else "der"
    edge_color, line_style = border_colors[format_type]
    fill_color = palette[i]
    
    sns.boxplot(
        data=data[data["Type"] == type_],
        x="Time (s)", y="Type", whis=[0, 100],
        width=0.6, color=fill_color,  # Set fill color
        ax=ax, boxprops=dict(edgecolor=edge_color, linewidth=1, linestyle=line_style)  # Set edge color and dashed style
    )

# Overlay individual data points with corresponding box colors
for i, type_ in enumerate(data["Type"].unique()):
    sns.stripplot(
        data=data[data["Type"] == type_],
        x="Time (s)", y="Type", size=2,
        color=palette[i], jitter=True, ax=ax
    )

# Set x-axis limits
ax.set_xlim(0, 25)  # Adjusted to reflect seconds, assuming the max time in ms is 25000

# Customize the visual presentation further
ax.xaxis.grid(True)
ax.set_ylabel("Type", fontsize=19)  # Increase the font size of y-axis label
ax.set_xlabel("Time (s)", fontsize=19)  # Increase the font size of x-axis label

# Increase font size of tick labels
ax.tick_params(axis="x", labelsize=15)  # X-axis ticks
ax.tick_params(axis="y", labelsize=15)  # Y-axis ticks

# Add a title to the plot
plt.title("MQTT", fontsize=22, pad=22)  # Increase title font size

# Adjust layout to make space for y-axis labels and prevent clipping
plt.subplots_adjust(left=0.18, right=0.87)  # Adjusted spacing on the left for labels

# Remove top and left spines to improve the appearance
sns.despine(trim=True, left=True)

# Create a custom legend with dashed and solid lines for 'txt' and 'pem'
legend_lines = [
    Line2D([0], [0], color="black", linestyle="solid", lw=2, label="pem (solid border)"),
    Line2D([0], [0], color="black", linestyle="dashed", lw=2, label="txt (dashed border)"),
    Line2D([0], [0], color="black", linestyle="dotted", lw=2, label="der (dotted border)")
]
ax.legend(handles=legend_lines, loc="center left", bbox_to_anchor=(0.81, 0.85), fontsize=14)

# Save the plot as a PDF
plt.savefig("/home/giac/Pk-IOTA/tests/IOTA/mqtt_test_results/plot_mqtt.pdf", format="pdf")

# Show the plot
plt.show()
