-include .env

.PHONY: all test deploy help anvil 

DEFAULT_ANVIL_KEY := 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80


NETWORK_ARGS := --rpc-url http://localhost:8545 --private-key $(DEFAULT_ANVIL_KEY) --broadcast

ifeq ($(findstring --network sepolia,$(ARGS)),--network sepolia)
	NETWORK_ARGS := --rpc-url $(SEPOLIA_RPC_URL) --account myaccount --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv
endif

ifeq ($(findstring --network merlinTest,$(ARGS)),--network merlinTest)
	NETWORK_ARGS := --rpc-url $(MERLIN_TEST_RPC_URL) --account myaccount --broadcast  -vvvv
endif

deploy:
	@forge script script/DeployProtocol.s.sol:DeployProtocol[$(PUBLIC_KEY)] $(NETWORK_ARGS)
