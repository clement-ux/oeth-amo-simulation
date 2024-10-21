import json

with open('../snapshots/SimulateSwapOldPool.json', "r") as file:
    oldPool = json.load(file)

with open('../snapshots/SimulateSwapNewPool.json', "r") as file:
    newPool = json.load(file)

def avg(json_data):
    return sum([float(v) for v in json_data.values()]) / len(json_data)

print("Old pool avg gas: ", "{:.0f}".format(avg(oldPool)))
print("New pool avg gas: ", "{:.0f}".format(avg(newPool)))
print("Difference in % : ", "{:.2f}".format((avg(newPool) - avg(oldPool)) / avg(oldPool) * 100), "%")

# format with just 2 decimals
