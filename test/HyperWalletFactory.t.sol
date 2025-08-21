// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";

import {HyperWalletFactory} from "../src/HyperWalletFactory.sol";
import {IHyperWallet} from "../src/interfaces/IHyperWallet.sol";

contract HyperWalletFactoryTest is Test {
    HyperWalletFactory internal walletFactory;

    address user1 = address(0xABCD);
    address user2 = address(0xAABB);
    address module1 = address(0xABAB);
    address module2 = address(0xBCCB);

    address token = address(0xAAAA);
    address tokenSystemAddress = address(0xABBB);

    function setUp() public {
        uint256 forkId = vm.createFork("hl_mainnet");
        vm.selectFork(forkId);

        walletFactory = new HyperWalletFactory(address(this));
    }

    function testDeploy() external {
        assertEq(address(this), walletFactory.owner());
    }

    function testWalletCreation() external {
        vm.prank(user1);
        address newWallet = walletFactory.createWallet(user1);
        assertEq(IHyperWallet(newWallet).walletId(), 0);
    }

    function testEnableModule() external {
        vm.startPrank(user1);
        vm.expectRevert();
        walletFactory.toggleModule(module1, true);
        vm.stopPrank();

        walletFactory.toggleModule(module1, true);
        walletFactory.toggleModule(module2, true);
        assertEq(walletFactory.modules(module1), true);
        assertEq(walletFactory.modules(module2), true);
        walletFactory.toggleModule(module1, false);
        walletFactory.toggleModule(module2, false);
        assertEq(walletFactory.modules(module1), false);
        assertEq(walletFactory.modules(module2), false);
    }

    function testSetSystemAddress() external {
        vm.startPrank(user1);
        vm.expectRevert();
        walletFactory.setSystemAddress(token, tokenSystemAddress);
        vm.stopPrank();

        walletFactory.setSystemAddress(token, tokenSystemAddress);
        assertEq(walletFactory.systemAddress(token), tokenSystemAddress);
    }

    function testTransferOwnership() external {
        walletFactory.transferOwnership(user1);
        vm.prank(user1);
        walletFactory.acceptOwnership();
        assertEq(walletFactory.owner(), user1);
    }
}
