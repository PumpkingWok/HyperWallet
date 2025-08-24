// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Script.sol";
import {TokenBook} from "../src/utils/TokenBook.sol";
import {FlashLoanModule} from "../src/modules/flashLoan/FlashLoanModule.sol";

contract DeployFlashLoan is Script {
    function run() external returns (TokenBook tokenBook, FlashLoanModule flashLoan) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);

        tokenBook = new TokenBook(deployer);

        flashLoan = new FlashLoanModule(address(tokenBook), "FlashLoan", "1.0");

        vm.stopBroadcast();

        console2.log("TokenBook deployed at:", address(tokenBook));
        console2.log("FlashLoanModule deployed at:", address(flashLoan));
    }
}
