import json
import matplotlib.pyplot as plt
import matplotlib.gridspec as gridspec

# Load data (unchanged)
with open('../test/json/SimulateSwapNewPool_Input.json', "r") as file:
    input = json.load(file)

with open('../test/json/SimulateSwapNewPool_Output.json', "r") as file:
    output = json.load(file)

def convert_pct_to_share(pct):
    total = pct / 1e18 + 1
    pct_token_1 = (pct / 1e18) / total * 100
    pct_token_0 = f"{100 - pct_token_1:.0f}"
    pct_token_1 = f"{pct_token_1:.0f}"
    return f"{pct_token_0}/{pct_token_1}"

# Get data
KEYS = [K for K in input.keys()]
A_FACTORS = [a for a in input[KEYS[0]]]
AMO_PCT = [pct for pct in input[KEYS[1]]]
SWAP_PCT = [pct for pct in input[KEYS[2]]]

X = [x for x in SWAP_PCT]

# Create figure
fig = plt.figure(figsize=(20, 12))
gs = gridspec.GridSpec(2, 2, figure=fig, hspace=0.3, wspace=0.3)

# Create subplots with a common y-axis scale
axes = []
y_min, y_max = float('inf'), float('-inf')

for i in range(len(A_FACTORS)):
    ax = fig.add_subplot(gs[i // 2, i % 2])
    axes.append(ax)
    
    for j in range(len(AMO_PCT)):
        y_data = output[str(A_FACTORS[i])][f"{AMO_PCT[j]:.0f}"]
        ax.plot(X, y_data, label=convert_pct_to_share(AMO_PCT[j]), linewidth=1.5)
        
        y_min = min(y_min, min(y_data))
        y_max = max(y_max, max(y_data))
    
    ax.set_title(f"A factor: {A_FACTORS[i]}", fontsize=14)
    ax.grid(True, which="both", linestyle="--", alpha=0.5)
    ax.set_xlabel("% of pool swapped", fontsize=12)
    ax.set_ylabel("% obtained", fontsize=12)

# Set common y-axis limits
y_range = y_max - y_min
for ax in axes:
    ax.set_ylim(y_min - 0.05 * y_range, y_max + 0.05 * y_range)

# Add a common legend
handles, labels = axes[-1].get_legend_handles_labels()
fig.legend(handles, labels, title="Pool Share", loc='center right', bbox_to_anchor=(0.98, 0.5), fontsize=10)

# Add a main title
fig.suptitle("Comparison of % Obtained vs % of Pool Swapped for Different A Factors", fontsize=16, y=0.98)

plt.tight_layout(rect=[0, 0.03, 0.85, 0.95])

# Save the figure
plt.savefig("./png/SwapComparisonNewPool.png", dpi=300, bbox_inches='tight')