# Uniswap V2 USDT & WETH Interactions

This repository contains a smart contract (`Submission.sol`) that interacts with Uniswap V2 to perform token swaps and add liquidity, specifically designed to safely handle USDT's non-standard ERC20 behavior.

## Overview
USDT on Ethereum mainnet does not return a boolean on standard operations like `approve` or `transferFrom`, which causes standard OpenZeppelin ERC20 interfaces to revert. This project implements low-level `.call` wrappers to safely pull USDT, approve the Uniswap V2 Router, and handle routing without failing.

### Features
* **Safe USDT Wrappers**: Custom `_safeTransferFrom`, `_safeApprove`, and `_safeTransfer` implementations.
* **`swapUsdtForWeth`**: Pulls USDT from the caller and executes a swap for WETH on Uniswap V2.
* **`addUsdtWethLiquidity`**: Pulls both USDT and WETH from the caller, provisions liquidity to the UniswapV2 pool, and refunds any unused dust to the caller.

## Testing
This project uses Foundry. The test suite forks mainnet to verify interactions against live Uniswap contracts and mainnet whale accounts.

```bash
# Add an archive node RPC to your .env file
echo "MAINNET_RPC_URL=https://your_rpc_url_here" > .env

# Run the tests against mainnet fork
forge test -vvv
```
