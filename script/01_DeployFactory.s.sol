// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Script.sol";
import {HyperWalletFactory} from "../src/HyperWalletFactory.sol";

contract DeployFactory is Script {
    function run() external returns (HyperWalletFactory factory) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        factory = new HyperWalletFactory(vm.addr(deployerPrivateKey));

        vm.stopBroadcast();

        console2.log("HyperWalletFactory deployed at:", address(factory));
        console2.log("HyperWallet implementation deployed at:", factory.HYPER_WALLET());
    }
}
