// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Script.sol";
import {CoreWriterSdkSecurityModule} from "../src/modules/coreWriter/CoreWriterSdkSecurityModule.sol";

contract DeployCoreWriterSdkSecurity is Script {
    // testnet value
    uint64 hypeCoreTokenId = 1105;
    uint64 usdcCoreTokenId = 0;

    function run() external returns (CoreWriterSdkSecurityModule coreWriterSdkSecurity) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        coreWriterSdkSecurity =
            new CoreWriterSdkSecurityModule(hypeCoreTokenId, usdcCoreTokenId, "CoreWriterSdkSecurity", "1.0");

        vm.stopBroadcast();

        console2.log("CoreWriterSdkSecurityModule deployed at:", address(coreWriterSdkSecurity));
    }
}
