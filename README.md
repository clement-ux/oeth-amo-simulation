## Swap comparison on Curve pool (old and new gen)

You can set up swap parameter in json called `SimulateSwapOldPool_Input` and `SimulateSwapNewPool_Input`. 

You can put unlimited amount of `A_FACTOR`, `AMO_PCT` and `SWAP_PCT`.

- `A_FACTOR` is the A in the Curve pool.
- `AMO_PCT` represent the % of the pool of oETH you want to add to the pool. Example
  - 0 -> 50/50
  - 1 -> 33/67
  - 2 -> 25/75
  - ...
- `SWAP_PCT` represent the % of ETH in reserve on the pool to swap in OETH.

Before all:
```
make install
make default
```

To run simulation:
```
make test-c-SimulationSwap
```

To run graphs (don't forget to change pool name for Old or New):
```
cd script
python graph.py
```

To run gas comparison:
```
cd script
python gas.py
```
