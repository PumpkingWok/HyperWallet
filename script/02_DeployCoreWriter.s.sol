// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Script.sol";
import {CoreWriterModule} from "../src/modules/coreWriter/CoreWriterModule.sol";

contract DeployCoreWriter is Script {
    function run() external returns (CoreWriterModule coreWriter) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        coreWriter = new CoreWriterModule("CoreWriter", "1.0");

        vm.stopBroadcast();

        console2.log("CoreWriterModule deployed at:", address(coreWriter));
    }
}
