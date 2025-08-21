// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";

import {HyperWalletFactory} from "../../src/HyperWalletFactory.sol";
import {IHyperWallet} from "../../src/interfaces/IHyperWallet.sol";
import {CoreWriterSdkModule} from "../../src/modules/coreWriter/CoreWriterSdkModule.sol";

abstract contract CoreWriterSdkTest is Test {
    HyperWalletFactory internal walletFactory;
    CoreWriterSdkModule internal coreWriterSdk;

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

        coreWriterSdk = new CoreWriterSdkModule("CoreWriterSdk", "1.0");
        walletFactory.toggleModule(address(coreWriterSdk), true);

        vm.prank(user1);
        IHyperWallet(user1Wallet).toggleModule(address(coreWriterSdk), true);
    }

    function testLimitOrder() external {
        vm.startPrank(user1);

        coreWriterSdk.limitOrder(user1Wallet, 0, true, 0, 0, true, 0, 0);
    }

    function testStakingDeposit() external {
        vm.prank(user1);
        coreWriterSdk.stakingDeposit(user1Wallet, 1e18);
        // check the event emitted
    }

    function testStakingWithdraw() external {
        vm.prank(user1);
        coreWriterSdk.stakingWithdraw(user1Wallet, 1e18);
    }

    function testSendUSdc() external {
        vm.prank(user1);
        coreWriterSdk.usdClassTransfer(user1Wallet, 1e6, true);
    }
}

contract CoreWriterSdkTestTestnet is CoreWriterSdkTest("hl_testnet") {}

//contract CoreWriterSdkTestMainnet is CoreWriterSdkTest("hl_mainnet") {}
