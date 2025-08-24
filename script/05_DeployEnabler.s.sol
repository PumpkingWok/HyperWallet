// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Script.sol";
import {EnablerModule} from "../src/modules/enabler/EnablerModule.sol";

contract DeployEnabler is Script {
    // testnet value
    uint64 hypeCoreTokenId = 1105;
    uint64 usdcCoreTokenId = 0;
    address usdcSystemAddress = 0x2000000000000000000000000000000000000000;
    address usdcTokenAddress = 0xd9CBEC81df392A88AEff575E962d149d57F4d6bc;

    function run() external returns (EnablerModule enabler) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        enabler = new EnablerModule(
            hypeCoreTokenId,
            usdcCoreTokenId,
            usdcSystemAddress,
            usdcTokenAddress,
            vm.addr(deployerPrivateKey),
            "Enabler",
            "1.0"
        );

        vm.stopBroadcast();

        console2.log("EnablerModule deployed at:", address(enabler));
    }
}
