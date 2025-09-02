// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";

import {HyperWalletFactory} from "../../src/HyperWalletFactory.sol";
import {IHyperWallet} from "../../src/interfaces/IHyperWallet.sol";
import {EnablerModule} from "../../src/modules/enabler/EnablerModule.sol";
import {ERC20} from "solady/tokens/ERC20.sol";
import {ModuleTest} from "./Module.t.sol";

abstract contract EnablerTest is ModuleTest {
    EnablerModule internal enabler;

    address recipient = address(0xAABB);

    uint64 hypeCoreTokenId;
    uint64 usdcCoreTokenId;
    address usdcSystemAddress;
    address usdc;

    constructor(
        uint64 _hypeCoreTokenId,
        uint64 _usdcCoreTokenId,
        address _usdcSystemAddress,
        address _usdc,
        string memory _forkRpc
    ) {
        hypeCoreTokenId = _hypeCoreTokenId;
        usdcCoreTokenId = _usdcCoreTokenId;
        usdcSystemAddress = _usdcSystemAddress;
        usdc = _usdc;
        forkRpc = _forkRpc;
    }

    function setUp() public override {
        super.setUp();

        enabler =
            new EnablerModule(hypeCoreTokenId, usdcCoreTokenId, usdcSystemAddress, usdc, recipient, "Enabler", "1.0");
        walletFactory.toggleModule(address(enabler), true);

        vm.prank(user1);
        IHyperWallet(user1Wallet).toggleModule(address(enabler), true);

        spotBalancePrecompile.setSpotBalance(
            address(enabler), hypeCoreTokenId, enabler.HYPE_ENABLER_AMOUNT_CORE(), 0, 0
        );
        spotBalancePrecompile.setSpotBalance(address(enabler), usdcCoreTokenId, enabler.USDC_ENABLER_AMOUNT(), 0, 0);

        deal(user1, 1e18);
        deal(usdc, user1, 1e8);

        vm.roll(block.number + 1);
    }

    function testEnableWallet() external {
        vm.startPrank(user1);
        ERC20(usdc).approve(address(enabler), enabler.USDC_ENABLER_AMOUNT());
        enabler.enableWalletOnCore{value: uint256(enabler.HYPE_ENABLER_AMOUNT_EVM())}(user1Wallet);
    }

    function testEnableWalletTwice() external {
        vm.startPrank(user1);
        ERC20(usdc).approve(address(enabler), enabler.USDC_ENABLER_AMOUNT() * 2);
        uint256 hypeEnablerAmount = uint256(enabler.HYPE_ENABLER_AMOUNT_EVM());
        enabler.enableWalletOnCore{value: hypeEnablerAmount}(user1Wallet);
        vm.roll(block.number + 1);

        // simulate enabling the wallet at core side
        coreUserExistsPrecompile.setCoreUserExists(user1Wallet, true);

        vm.expectRevert(EnablerModule.WalletAlreadyEnabled.selector);
        enabler.enableWalletOnCore{value: hypeEnablerAmount}(user1Wallet);
    }

    function testRetrieveToken() external {
        vm.startPrank(recipient);
        enabler.retrieveTokenFromCore();
    }
}

contract EnablerTestTestnet is
    EnablerTest(
        1105,
        0,
        0x2000000000000000000000000000000000000000,
        0xd9CBEC81df392A88AEff575E962d149d57F4d6bc,
        "hl_testnet"
    )
{}

//contract EnablerTestMainnet is EnablerTest(107, "hl_mainnet") {}
