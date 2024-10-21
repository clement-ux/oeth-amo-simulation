-include .env

.EXPORT_ALL_VARIABLES:
MAKEFLAGS += --no-print-directory

default:
	forge fmt && forge build

# Always keep Forge up to date
install:
	foundryup
	forge soldeer install

clean:
	@rm -rf broadcast cache out

clean-all:
	@rm -rf broadcast cache out dependencies node_modules soldeer.lock

gas:
	@forge test --gas-report

# Generate gas snapshots for all your test functions
snapshot:
	@forge snapshot

# Tests
test-std:
	forge test --summary --fail-fast --show-progress

test:
	@make test-std

test-f-%:
	@FOUNDRY_MATCH_TEST=$* make test-std

test-c-%:
	@FOUNDRY_MATCH_CONTRACT=$* make test-std

# Override default `test` and `coverage` targets
.PHONY: test coverage
