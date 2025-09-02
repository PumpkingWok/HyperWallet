// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";

import {HyperWalletFactory} from "../../src/HyperWalletFactory.sol";
import {MockCoreUserExists} from "../mocks/MockCoreUserExists.sol";
import {MockSpotBalance} from "../mocks/MockSpotBalance.sol";

abstract contract ModuleTest is Test {
    HyperWalletFactory internal walletFactory;
    MockSpotBalance internal spotBalancePrecompile;
    MockCoreUserExists internal coreUserExistsPrecompile;

    address user1 = address(0xBBBB);
    address user1Wallet;

    string forkRpc;

    function setUp() public virtual {
        uint256 forkId = vm.createFork(forkRpc);
        vm.selectFork(forkId);

        walletFactory = new HyperWalletFactory(address(this));
        user1Wallet = walletFactory.createWallet(user1);

        spotBalancePrecompile = new MockSpotBalance();
        vm.etch(0x0000000000000000000000000000000000000801, address(spotBalancePrecompile).code);
        spotBalancePrecompile = MockSpotBalance(0x0000000000000000000000000000000000000801);

        coreUserExistsPrecompile = new MockCoreUserExists();
        vm.etch(0x0000000000000000000000000000000000000810, address(coreUserExistsPrecompile).code);
        coreUserExistsPrecompile = MockCoreUserExists(0x0000000000000000000000000000000000000810);
    }
}
