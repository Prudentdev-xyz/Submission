// Repository: https://github.com/Prudentdev-xyz/Submission.git
// Commit: 37fa360f354a540c7b90fbfc975a20da109d8fef
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// --- Interfaces ---

interface IUniswapV2Router02 {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
}

interface IMinimalERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
}

// --- Main Contract ---
contract Submission {
    address public constant ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    /// @notice Swaps USDT for WETH using Uniswap V2
    function swapUsdtForWeth(
        uint256 amountIn,
        uint256 amountOutMin,
        address to
    ) external returns (uint256[] memory amounts) {
        require(amountIn > 0, "amountIn must be > 0");

        // 1. Pull USDT from msg.sender to this contract
        _safeTransferFrom(USDT, msg.sender, address(this), amountIn);

        // 2. Approve the Router to spend the USDT
        _safeApprove(USDT, ROUTER, amountIn);

        // 3. Execute the swap
        address[] memory path = new address[](2);
        path[0] = USDT;
        path[1] = WETH;

        amounts = IUniswapV2Router02(ROUTER).swapExactTokensForTokens(
            amountIn,
            amountOutMin,
            path,
            to,
            block.timestamp
        );
    }

    /// @notice Adds USDT and WETH liquidity to Uniswap V2
    function addUsdtWethLiquidity(
        uint256 usdtAmount,
        uint256 wethAmount,
        uint256 usdtMin,
        uint256 wethMin,
        address to
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity) {
        require(usdtAmount > 0 && wethAmount > 0, "amounts must be > 0");

        // 1. Pull both tokens from msg.sender to this contract
        _safeTransferFrom(USDT, msg.sender, address(this), usdtAmount);
        _safeTransferFrom(WETH, msg.sender, address(this), wethAmount);

        // 2. Approve the Router
        _safeApprove(USDT, ROUTER, usdtAmount);
        _safeApprove(WETH, ROUTER, wethAmount);

        // 3. Add liquidity
        (amountA, amountB, liquidity) = IUniswapV2Router02(ROUTER).addLiquidity(
            USDT,
            WETH,
            usdtAmount,
            wethAmount,
            usdtMin,
            wethMin,
            to,
            block.timestamp
        );

        // 4. Refund any unspent tokens back to msg.sender
        if (usdtAmount > amountA) {
            uint256 refundUSDT = usdtAmount - amountA;
            // For refunding, we need to transfer from this contract to msg.sender
            _safeTransfer(USDT, msg.sender, refundUSDT);
        }

        if (wethAmount > amountB) {
            uint256 refundWETH = wethAmount - amountB;
            _safeTransfer(WETH, msg.sender, refundWETH);
        }
    }

    // --- Internal Safe Helpers ---
    // USDT requires special handling because it does not return a boolean on success.
    // If we use standard interfaces that expect a bool, the call will revert.

    function _safeTransfer(address token, address to, uint256 value) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSignature("transfer(address,uint256)", to, value)
        );
        require(success && (data.length == 0 || abi.decode(data, (bool))), "SafeTransfer: failed");
    }

    function _safeTransferFrom(address token, address from, address to, uint256 value) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSignature("transferFrom(address,address,uint256)", from, to, value)
        );
        require(success && (data.length == 0 || abi.decode(data, (bool))), "SafeTransferFrom: failed");
    }

    function _safeApprove(address token, address spender, uint256 value) internal {
        // USDT's approve also has quirk: you can't approve a new value if current allowance > 0.
        // It's safest to reset it to 0 first if we want to be foolproof, but for simplicity
        // in this exact flow (single transaction scope, pulling precise amounts), a direct approve works.
        // If it reverts, resetting to 0 first is the fix. Let's just reset to 0 then set value to be 100% safe.
        
        (bool success1, ) = token.call(
            abi.encodeWithSignature("approve(address,uint256)", spender, 0)
        );
        require(success1, "SafeApprove: reset failed");

        (bool success2, bytes memory data) = token.call(
            abi.encodeWithSignature("approve(address,uint256)", spender, value)
        );
        require(success2 && (data.length == 0 || abi.decode(data, (bool))), "SafeApprove: failed");
    }
}
