// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";

import {HyperWalletFactory} from "../../src/HyperWalletFactory.sol";
import {IHyperWallet} from "../../src/interfaces/IHyperWallet.sol";
import {CoreWriterModule} from "../../src/modules/coreWriter/CoreWriterModule.sol";

abstract contract CoreWriterTest is Test {
    HyperWalletFactory internal walletFactory;
    CoreWriterModule internal coreWriter;

    address user1 = address(0xABCD);
    address user1Wallet;

    string forkRpc;

    constructor(string memory _forkRpc) {
        forkRpc = _forkRpc;
    }

    function setUp() public {
        uint256 forkId = vm.createFork(forkRpc);
        vm.selectFork(forkId);

        walletFactory = new HyperWalletFactory(address(this));
        user1Wallet = walletFactory.createWallet(user1);

        coreWriter = new CoreWriterModule("CoreWriter", "1.0");
        walletFactory.toggleModule(address(coreWriter), true);

        vm.prank(user1);
        IHyperWallet(user1Wallet).toggleModule(address(coreWriter), true);
    }

    function testDeploy() external {
        assertEq(coreWriter.name(), "CoreWriter");
        assertEq(coreWriter.version(), "1.0");
    }

    function testDoAction() external {
        vm.startPrank(user1);
        bytes memory actionData;
        coreWriter.doAction(user1Wallet, actionData);
    }

    function testDoActions() external {
        vm.startPrank(user1);
        bytes[] memory actionsData;
        coreWriter.doActions(user1Wallet, actionsData);
    }

    function testDoActionParams() external {
        vm.startPrank(user1);
        bytes memory actionArgs;
        coreWriter.doAction(user1Wallet, 0x01, 0x000001, actionArgs);
    }
}

contract CoreWriterTestTestnet is CoreWriterTest("hl_testnet") {}

contract CoreWriterTestMainnet is CoreWriterTest("hl_mainnet") {}
