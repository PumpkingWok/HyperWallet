// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Script.sol";
import {CoreWriterSdkModule} from "../src/modules/coreWriter/CoreWriterSdkModule.sol";

contract DeployCoreWriterSdk is Script {
    function run() external returns (CoreWriterSdkModule coreWriterSdk) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        coreWriterSdk = new CoreWriterSdkModule("CoreWriterSdk", "1.0");

        vm.stopBroadcast();

        console2.log("CoreWriterSdkModule deployed at:", address(coreWriterSdk));
    }
}
