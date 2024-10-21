// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.27;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {stdJson} from "forge-std/StdJson.sol";

import {IOETH} from "src/IOETH.sol";
import {IWETH9} from "src/IWETH9.sol";
import {ICurveStableSwapNG} from "src/ICurveStableSwapNG.sol";
import {ICurveStableswapFactoryNG} from "src/ICurveStableswapFactoryNG.sol";

contract SimulateSwapNewPool is Test {
    using stdJson for string;

    ////////////////////////////////////////////////////
    /// --- STRUCTS & ENUMS
    ////////////////////////////////////////////////////
    struct JSON {
        // Note: Json key should be ordered in alphabetical order!
        uint256[] A;
        uint256[] AMO_PCT;
        uint256[] SWAP_PCT;
    }

    ////////////////////////////////////////////////////
    /// --- CONSTANTS & IMMUTABLES
    ////////////////////////////////////////////////////
    address public constant OWNER = 0x40907540d8a6C65c637785e8f8B742ae6b0b9968;
    address public constant VAULT = 0x39254033945AA2E4809Cc2977E7087BEE48bd7Ab;
    uint256 public constant WAD = 1e18;

    // Token 0 = ETH
    // Token 1 = oETH

    ////////////////////////////////////////////////////
    /// --- STORAGE
    ////////////////////////////////////////////////////
    string jsonPathInput = "/test/json/SimulateSwapNewPool_Input.json";
    string jsonPathOutput = "/test/json/SimulateSwapNewPool_Output.json";

    ICurveStableSwapNG public pool;
    IOETH public oeth = IOETH(payable(0x856c4Efb76C1D1AE02e20CEB03A2A6a08b0b8dC3));
    IWETH9 public weth = IWETH9(payable(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2));
    ICurveStableswapFactoryNG public factory = ICurveStableswapFactoryNG(0x6A8cbed756804B16E05E741eDaBd5cB544AE21bf);

    ////////////////////////////////////////////////////
    /// --- MODIFIERS
    ////////////////////////////////////////////////////
    modifier isolate() {
        uint256 id = vm.snapshot();
        _;
        vm.revertToAndDelete(id);
    }

    ////////////////////////////////////////////////////
    /// --- SETUP
    ////////////////////////////////////////////////////
    function setUp() public {
        vm.createSelectFork("mainnet");

        // 0: WETH
        // 1: oETH
        address[] memory coins = new address[](2);
        coins[0] = address(weth);
        coins[1] = address(oeth);

        // 0: Standard
        // 1: Oracle
        // 2: Rebasing
        // 3: ERC4626
        uint8[] memory assetTypes = new uint8[](2);
        assetTypes[0] = 0; //
        assetTypes[1] = 2;

        // Useful for oracle tokens
        bytes4[] memory methodIds = new bytes4[](2);

        // Useful for oracle tokens
        address[] memory oracles = new address[](2);

        // Deploy new gen pool
        address newPool = factory.deploy_plain_pool(
            "Curve ETH/oETH", // name
            "crvETHoETH", // symbol
            coins, // coins WETH and oETH
            400, // A factor
            4000000, // fee
            0, // offpeg fee multiplier
            866, // ma exp time
            0, // implementation idx
            assetTypes, // asset types
            methodIds, // method ids
            oracles // oracles
        );

        // Cache new address
        pool = ICurveStableSwapNG(newPool);
        vm.label(newPool, "Curve ETH/oETH New Gen");

        // Approve pool to spend tokens
        weth.approve(address(pool), type(uint256).max);
        oeth.approve(address(pool), type(uint256).max);

        // Seed pool with liquidity
        addLiquidity(5_000 ether, 5_000 ether);

        // Do some swaps to avoid non-initialized values and get wrong gas measurements
        swapOETHForETH(1 ether);
        swapWETHForOETH(1 ether);

        // Equalize the pool balance
        equalizePoolBalance();
    }

    function test_SimulateSwapNewPool() public {
        JSON memory values = getJsonValue();

        uint256 lenA = values.A.length;
        uint256 lenAMO = values.AMO_PCT.length;
        uint256 lenSWAP = values.SWAP_PCT.length;

        uint256[][][] memory output = new uint256[][][](lenA);
        for (uint256 i; i < lenA; i++) {
            output[i] = new uint256[][](lenAMO);
            for (uint256 j; j < lenAMO; j++) {
                output[i][j] = new uint256[](lenSWAP);
                for (uint256 k; k < lenSWAP; k++) {
                    output[i][j][k] = tx_(values.A[i], values.AMO_PCT[j], values.SWAP_PCT[k]);
                }
            }
        }
        writeInJson(output);
    }

    function tx_(uint256 aFactor, uint256 amoPct, uint256 swapPct) public isolate returns (uint256) {
        // Increase A factor to needed value
        ramp_A(aFactor);

        // Equalize the pool balance
        equalizePoolBalance();

        // Pump liquidity
        if (amoPct > 0) pumpLiquidity(amoPct);

        // Swap
        uint256 amountIn = getAmountToSwap(swapPct);

        vm.startSnapshotGas(
            string.concat("A: ", vm.toString(aFactor), " AMO: ", vm.toString(amoPct), " SWAP: ", vm.toString(swapPct))
        );
        uint256 amountOut = swapOETHForETH(amountIn);
        vm.stopSnapshotGas();

        // Return % slippage
        return amountOut * WAD / amountIn;
    }

    ////////////////////////////////////////////////////
    /// --- JSON
    ////////////////////////////////////////////////////
    function getJsonValue() public view returns (JSON memory) {
        string memory path = string.concat(vm.projectRoot(), jsonPathInput);
        string memory json = vm.readFile(path);
        bytes memory data = vm.parseJson(json);
        return abi.decode(data, (JSON));
    }

    function writeInJson(uint256[][][] memory values) public {
        string memory path = string.concat(vm.projectRoot(), jsonPathOutput);
        JSON memory json = getJsonValue();

        // Step 1: Prepare the A in JSON
        // {
        //    "100": "",
        //    "500": "",
        //    "1000": "",
        //    "2000": ""
        // }
        //
        string memory obj = "random";
        uint256 lenA = json.A.length;
        for (uint256 i; i < lenA - 1; i++) {
            vm.serializeString(obj, vm.toString(json.A[i]), "");
        }
        string memory f = vm.serializeString(obj, vm.toString(json.A[lenA - 1]), "");
        vm.writeJson(f, path);

        // Step 2: Write the values in JSON for each A and AMO_PCT
        // {
        //    "100": {
        //      "1": [1,2,3 ...],
        //      "2": [1,2,3 ...],
        //      "3": [1,2,3 ...],
        //      "4": [1,2,3 ...]
        //    },
        //    "500": {
        //      "1": [1,2,3 ...],
        //      ...
        //    }
        //     ...
        // }
        //
        string memory obj1 = "random1";
        uint256 lenAMO = json.AMO_PCT.length;

        for (uint256 i; i < lenA; i++) {
            for (uint256 j; j < lenAMO - 1; j++) {
                vm.serializeUint(obj1, vm.toString(json.AMO_PCT[j]), values[i][j]);
            }
            string memory f1 = vm.serializeUint(obj1, vm.toString(json.AMO_PCT[lenAMO - 1]), values[i][lenAMO - 1]);
            vm.writeJson(f1, path, string.concat(".", vm.toString(json.A[i])));
        }
    }

    ////////////////////////////////////////////////////
    /// --- HELPERS
    ////////////////////////////////////////////////////
    function mintOETH(uint256 amount) public {
        vm.prank(VAULT);
        oeth.mint(address(this), amount);
    }

    function addLiquidityOETH(uint256 amount) public returns (uint256) {
        mintOETH(amount);
        uint256[] memory amounts = new uint256[](2);
        amounts[1] = amount;
        return pool.add_liquidity(amounts, 0);
    }

    function addLiquidityWETH(uint256 amount) public returns (uint256) {
        deal(address(weth), address(this), amount);
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = amount;
        return pool.add_liquidity(amounts, 0);
    }

    function addLiquidity(uint256 amountWETH, uint256 amountOETH) public returns (uint256) {
        mintOETH(amountOETH);
        deal(address(weth), address(this), amountWETH);
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = amountWETH;
        amounts[1] = amountOETH;
        return pool.add_liquidity(amounts, 0);
    }

    function equalizePoolBalance() public {
        uint256[] memory balances = pool.get_balances();
        if (balances[0] > balances[1]) {
            addLiquidityOETH(balances[0] - balances[1]);
        }
        if (balances[0] < balances[1]) {
            addLiquidityWETH(balances[1] - balances[0]);
        }
    }

    function pumpLiquidity(uint256 pct) public {
        uint256[] memory balances = pool.get_balances();
        uint256 amount = balances[0] * (pct) / WAD;
        addLiquidityOETH(amount);
    }

    function ramp_A(uint256 futurA) public {
        vm.startPrank(OWNER);
        pool.ramp_A(futurA, block.timestamp + 1 days);
        skip(1 days);
        require(pool.A() == futurA, "A factor not reached");
        vm.stopPrank();
    }

    function swapOETHForETH(uint256 amount) public returns (uint256) {
        mintOETH(amount);
        uint256 amountOut = pool.exchange(int128(1), int128(0), amount, 0);

        //console.log("Amount of oETH sent   : %18e", amount);
        //console.log("Amount of ETH obtained: %18e", amountOut);

        return amountOut;
    }

    function swapWETHForOETH(uint256 amount) public returns (uint256) {
        deal(address(weth), address(this), amount);
        uint256 amountOut = pool.exchange(int128(0), int128(1), amount, 0);

        //console.log("Amount of WETH sent   : %18e", amount);
        //console.log("Amount of oETH obtained: %18e", amountOut);

        return amountOut;
    }

    function getAmountToSwap(uint256 pct) public view returns (uint256) {
        uint256[] memory balances = pool.get_balances();
        return balances[0] * pct / WAD;
    }
}
