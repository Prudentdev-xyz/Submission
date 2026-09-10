// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/Submission.sol";

// We need an interface for the Uniswap V2 Pair to check LP balances
interface IUniswapV2Pair {
    function balanceOf(address owner) external view returns (uint256);
}

// We need an interface for token approvals from the test user's perspective
interface ITestERC20 {
    function approve(address spender, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external;
}

contract SubmissionTest is Test {
    Submission public submission;

    address constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant WHALE = 0x28C6c06298d514Db089934071355E5743bf21d60; // Binance 14
    address constant PAIR = 0x0d4a11d5EEaaC28EC3F61d100daF4d40471f1852; // USDT-WETH Pair

    address testUser = address(0x1234);

    function setUp() public {
        vm.createSelectFork(vm.envString("MAINNET_RPC_URL"), 25_949_200);
        submission = new Submission();

        // Prank whale to fund testUser
        vm.startPrank(WHALE);
        // Transfer 10,000 USDT (USDT has 6 decimals)
        ITestERC20(USDT).transfer(testUser, 10_000 * 1e6);
        // Transfer 10 WETH
        ITestERC20(WETH).transfer(testUser, 10 * 1e18);
        vm.stopPrank();
    }

    function testSwapUsdtForWeth() public {
        uint256 amountIn = 1000 * 1e6; // 1000 USDT
        
        vm.startPrank(testUser);
        // Approve Submission contract (we must use low-level call for USDT approve because it lacks bool return)
        (bool success, ) = USDT.call(abi.encodeWithSignature("approve(address,uint256)", address(submission), amountIn));
        require(success, "USDT approve failed");

        uint256 wethBefore = ITestERC20(WETH).balanceOf(testUser);
        
        submission.swapUsdtForWeth(amountIn, 0, testUser);
        
        uint256 wethAfter = ITestERC20(WETH).balanceOf(testUser);
        vm.stopPrank();

        assertGt(wethAfter, wethBefore, "WETH balance did not increase");
    }

    function testAddUsdtWethLiquidity() public {
        uint256 usdtAmount = 1000 * 1e6;
        uint256 wethAmount = 1 * 1e18;
        
        vm.startPrank(testUser);
        // Approve Submission contract
        (bool success1, ) = USDT.call(abi.encodeWithSignature("approve(address,uint256)", address(submission), usdtAmount));
        require(success1, "USDT approve failed");
        ITestERC20(WETH).approve(address(submission), wethAmount);

        uint256 lpBefore = IUniswapV2Pair(PAIR).balanceOf(testUser);
        
        submission.addUsdtWethLiquidity(usdtAmount, wethAmount, 0, 0, testUser);
        
        uint256 lpAfter = IUniswapV2Pair(PAIR).balanceOf(testUser);
        vm.stopPrank();

        assertGt(lpAfter, lpBefore, "LP balance did not increase");
    }
}
