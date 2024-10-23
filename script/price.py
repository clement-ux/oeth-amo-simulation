import json
import matplotlib.pyplot as plt
import matplotlib.gridspec as gridspec

# Load data (unchanged)
with open('../test/json/GetPrice_Input.json', "r") as file:
    input = json.load(file)

with open('../test/json/GetPrice_Output.json', "r") as file:
    output = json.load(file)


def convert_pct_to_share(pct):
    pct_token0 = 1
    pct_token1 = 1 + pct / 1e18
    total = pct_token0 + pct_token1
    return f"{pct_token0 * 100 / total:.0f}"+"/"+f"{pct_token1 * 100 / total:.0f}"

# Get data
KEYS = [K for K in input.keys()]
A_FACTORS = [a for a in input[KEYS[0]]]
AMO_PCT = [pct for pct in input[KEYS[1]]]
SWAP_PCT = 1e18

X = [a for a in A_FACTORS]

fig, axis = plt.subplots(figsize=(16, 10))


for i in range(len(AMO_PCT)):
    y_data = []
    for j in range(len(A_FACTORS)):
        y_data.append(output[f"{A_FACTORS[j]}"][f"{AMO_PCT[i]:.0f}"][0])
    axis.plot(X, y_data, label = convert_pct_to_share(AMO_PCT[i]), linewidth=0.8)
    
axis.grid(True, which="both", linestyle="--", alpha=0.5)
axis.set_title("Price OETH/ETH", fontsize=14)
axis.set_xlabel("A factor", fontsize=12)
axis.set_ylabel("Price", fontsize=12)

fig.legend()
plt.show()
