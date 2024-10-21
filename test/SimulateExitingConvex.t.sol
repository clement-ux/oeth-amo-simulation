// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.27;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";

import {IOETH} from "src/IOETH.sol";
import {IWETH9} from "src/IWETH9.sol";
import {ICurveGauge} from "src/ICurveGauge.sol";
import {ICurveLPToken} from "src/ICurveLPToken.sol";
import {IOETHVaultCore} from "src/IOETHVaultCore.sol";
import {IConvexEthMetaStrategy} from "src/IConvexEthMetaStrategy.sol";

contract SimulateExitingConvex is Test {
    uint256 public constant BLOCK_NUMBER = 20992573;
    uint256 public constant LIQUIDITY_MULTIPLIER = 1000 ether;

    IOETH public constant OETH = IOETH(payable(0x856c4Efb76C1D1AE02e20CEB03A2A6a08b0b8dC3));
    IWETH9 public constant WETH = IWETH9(payable(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2));
    ICurveGauge public constant GAUGE = ICurveGauge(0xd03BE91b1932715709e18021734fcB91BB431715);
    IOETHVaultCore public constant VAULT = IOETHVaultCore(0x39254033945AA2E4809Cc2977E7087BEE48bd7Ab);
    ICurveLPToken public constant LP_TOKEN = ICurveLPToken(0x94B17476A93b3262d87B9a326965D1E91f9c13E7);
    IConvexEthMetaStrategy public constant CONVEX_AMO =
        IConvexEthMetaStrategy(payable(0x1827F9eA98E0bf96550b2FC20F7233277FcD7E63));

    function setUp() public {
        vm.createSelectFork("mainnet", BLOCK_NUMBER);
        OETH.approve(address(LP_TOKEN), type(uint256).max);
        LP_TOKEN.approve(address(GAUGE), type(uint256).max);
    }

    function test_ExitConvex() public {
        // Remove all liqudity from Convex
        vm.prank(address(VAULT));
        CONVEX_AMO.withdrawAll();

        // Mint ETH
        uint256 balanceWETH = WETH.balanceOf(address(VAULT)) * 3 / 2;
        vm.deal(address(this), balanceWETH);

        // Mint OETH
        vm.prank(address(VAULT));
        OETH.mint(address(this), balanceWETH);

        // Deposit in Pool to get LP Token
        uint256[2] memory amounts = [balanceWETH, balanceWETH];
        LP_TOKEN.add_liquidity{value: balanceWETH}(amounts, 0);

        // Deposit token in gauge
        GAUGE.deposit(LP_TOKEN.balanceOf(address(this)));

        // check working supply and working balance
        uint256 working_balance = GAUGE.working_balances(address(this));
        uint256 working_supply = GAUGE.working_supply();

        console.log("ratio: %2e%", working_balance * 10_000 / working_supply);
    }
}
