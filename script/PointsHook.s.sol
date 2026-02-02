// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import {HookMiner} from "v4-periphery/src/utils/HookMiner.sol";
import {Hooks} from "v4-core/libraries/Hooks.sol"; 
import {PointsHook} from "../src/PointsHook.sol";

// Live run: forge script script/PointsHook.s.sol:PointsHookScript --rpc-url https://sepolia.base.org --chain-id 84532 --broadcast --verify
// Test run: forge script script/PointsHook.s.sol:PointsHookScript --rpc-url https://sepolia.base.org --chain-id 84532
contract PointsHookScript is Script {
    // https://getfoundry.sh/guides/deterministic-deployments-using-create2
    address internal constant CREATE2_DEPLOYER =
        0x4e59b44847b379578588920cA78FbF26c0B4956C;

    // https://docs.uniswap.org/contracts/v4/deployments base sepolia testnet:84532
    address internal constant POOL_MANAGER =
        0x05E73354cFDd6745C338b50BcFDfA3Aa6fA03408;

    function run() external {
        uint privateKey = vm.envUint("PRIVATE_KEY");

        uint160 flags = uint160(Hooks.AFTER_SWAP_FLAG);

        bytes memory constructorArgs = abi.encode(POOL_MANAGER);
        (address hookAddress, bytes32 salt) = HookMiner.find(
            CREATE2_DEPLOYER,
            flags,
            type(PointsHook).creationCode,
            constructorArgs
        );

        vm.startBroadcast(privateKey);
        PointsHook pointsHook = new PointsHook{salt: salt}(
            IPoolManager(POOL_MANAGER)
        );
        require(
            address(pointsHook) == hookAddress,
            "PointsHookScript: hook address mismatch"
        );

        vm.stopBroadcast();
    }
}
