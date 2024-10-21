// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.27;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {stdJson} from "forge-std/StdJson.sol";

import {IOETH} from "src/IOETH.sol";
import {ICurveLPToken} from "src/ICurveLPToken.sol";

contract SimulateSwapOldPool is Test {
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
    address public constant OWNER = 0x742C3cF9Af45f91B109a81EfEaf11535ECDe9571;
    address public constant VAULT = 0x39254033945AA2E4809Cc2977E7087BEE48bd7Ab;
    uint256 public constant WAD = 1e18;
    uint256 public constant BLOCK_NUMBER = 20992573;

    // Token 0 = ETH
    // Token 1 = oETH

    ////////////////////////////////////////////////////
    /// --- STORAGE
    ////////////////////////////////////////////////////
    string jsonPathInput = "/test/json/SimulateSwapOldPool_Input.json";
    string jsonPathOutput = "/test/json/SimulateSwapOldPool_Output.json";
    IOETH public oeth = IOETH(payable(0x856c4Efb76C1D1AE02e20CEB03A2A6a08b0b8dC3));
    ICurveLPToken public pool = ICurveLPToken(0x94B17476A93b3262d87B9a326965D1E91f9c13E7);

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
        vm.createSelectFork("mainnet", BLOCK_NUMBER);
        oeth.approve(address(pool), type(uint256).max);

        equalizePoolBalance();
    }

    function test_SimulateSwapOldPool() public {
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
        return pool.add_liquidity([0, amount], 0);
    }

    function addLiquidityETH(uint256 amount) public returns (uint256) {
        vm.deal(address(this), amount);
        return pool.add_liquidity{value: amount}([amount, 0], 0);
    }

    function addLiquidity(uint256 amountETH, uint256 amountOETH) public returns (uint256) {
        mintOETH(amountOETH);
        vm.deal(address(this), amountETH);
        return pool.add_liquidity{value: amountETH}([amountETH, amountOETH], 0);
    }

    function equalizePoolBalance() public {
        uint256[2] memory balances = pool.get_balances();
        if (balances[0] > balances[1]) {
            addLiquidityOETH(balances[0] - balances[1]);
        } else {
            addLiquidityETH(balances[1] - balances[0]);
        }
    }

    function pumpLiquidity(uint256 pct) public {
        uint256[2] memory balances = pool.get_balances();
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

    function getAmountToSwap(uint256 pct) public view returns (uint256) {
        uint256[2] memory balances = pool.get_balances();
        return balances[0] * pct / WAD;
    }

    receive() external payable {}
}
