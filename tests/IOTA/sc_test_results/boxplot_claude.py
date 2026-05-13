import seaborn as sns
import matplotlib.pyplot as plt
import pandas as pd
from matplotlib.lines import Line2D  # Import for custom legend lines

sns.set_theme(style="ticks")

# Initialize the figure with a more rectangular shape
f, ax = plt.subplots(figsize=(12, 9))  # Back to horizontal orientation

# Load the data from the CSV file
data = pd.read_csv("/home/giac/Pk-IOTA/tests/IOTA/sc_test_results/sc.csv")

# Remove 'Smart Contract' from the 'Type' column for visualization
data["Type"] = data["Type"].str.replace("Smart Contract", "", regex=False).str.strip()  # Rimuove spazi in eccesso

# Convert 'Time (ms)' from milliseconds to seconds
data["Time (s)"] = data["Time (ms)"] / 1000  # Divide by 1000 to convert ms to s

# Define base colors for each geographical distance
base_palette = {
    "EU-EU": ["#3b7196", "#9dbfeb"],   # Blu e celeste
    "EU-AUS": ["#aaafb3", "#d6cbcb"],  # Grigio celeste e grigio rosa
    "USA-AUS": ["#ff9896", "#a63f40"]  # Rosso e rosso chiaro
}

# Assign colors to each 'Type' based on its distance category
palette = [base_palette[type_.split()[0]][i % 2] for i, type_ in enumerate(data["Type"].unique())]

# Set border colors and styles for 'txt' and 'pem' formats
border_colors = {
    "txt": ("black", "dashed"),  # Black dashed border for txt formats
    "pem": ("black", "solid")  # Black solid border for pem formats
}

# Plot the boxplots with customized colors and borders
for i, type_ in enumerate(data["Type"].unique()):
    # Determine border color and fill color based on format and distance
    format_type = "txt" if "txt" in type_ else "pem"
    edge_color, line_style = border_colors[format_type]
    fill_color = palette[i]
    
    sns.boxplot(
        data=data[data["Type"] == type_],
        x="Time (s)", y="Type", whis=[0, 100],
        width=0.9,  # Maintain wide bar width
        color=fill_color,
        ax=ax, boxprops=dict(edgecolor=edge_color, linewidth=1.8, linestyle=line_style)
    )

# Overlay individual data points with corresponding box colors
for i, type_ in enumerate(data["Type"].unique()):
    sns.stripplot(
        data=data[data["Type"] == type_],
        x="Time (s)", y="Type", size=3,
        color=palette[i], jitter=True, ax=ax
    )

# Set x-axis limits
ax.set_xlim(0, 3)

# Customize the visual presentation further
ax.xaxis.grid(True)
ax.set_ylabel("Type", fontsize=28)
ax.set_xlabel("Time (s)", fontsize=28)

# Increase font size of tick labels
ax.tick_params(axis="x", labelsize=24)
ax.tick_params(axis="y", labelsize=24)


# Remove top and right spines and add spacing between bars
sns.despine(trim=True, left=True, bottom=True)
plt.subplots_adjust(left=0.2, right=1.2, top=1.0, bottom=0.0, hspace=0.7)  # Add vertical spacing between subplots

# Create a custom legend with dashed and solid lines for 'txt' and 'pem'
legend_lines = [
    Line2D([0], [0], color="black", linestyle="solid", lw=3, label="pem (solid border)"),
    Line2D([0], [0], color="black", linestyle="dashed", lw=3, label="txt (dashed border)")
]
# Maintain horizontal legend positioning
ax.legend(handles=legend_lines, loc="upper right", bbox_to_anchor=(0.8, 1.15), 
          ncol=3, fontsize=16)

# Save the plot as a PDF
plt.savefig("/home/giac/Pk-IOTA/tests/IOTA/mqtt_test_results/sc_doublecolumn.pdf", format="pdf")

# Show the plot
plt.show()