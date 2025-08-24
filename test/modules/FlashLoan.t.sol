// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";

import {HyperWalletFactory} from "../../src/HyperWalletFactory.sol";
import {IHyperWallet} from "../../src/interfaces/IHyperWallet.sol";
import {ITokenBook} from "../../src/interfaces/ITokenBook.sol";
import {FlashLoanModule} from "../../src/modules/flashLoan/FlashLoanModule.sol";
import {MockCoreUserExists} from "../mocks/MockCoreUserExists.sol";
import {MockSpotBalance} from "../mocks/MockSpotBalance.sol";
import {ERC20} from "solady/tokens/ERC20.sol";
import {TokenBook} from "../../src/utils/TokenBook.sol";

abstract contract FlashLoanTest is Test {
    HyperWalletFactory walletFactory;
    FlashLoanModule flashLoan;
    MockSpotBalance internal spotBalancePrecompile;
    MockCoreUserExists internal coreUserExistsPrecompile;
    TokenBook tokenBook;

    string forkRpc;

    address user1 = address(0xBBBB);
    address user1Wallet;

    address token;
    address tokenSystemAddress;
    uint64 tokenCoreId;

    constructor(address token_, address tokenSystemAddress_, uint64 tokenCoreId_, string memory forkRpc_) {
        forkRpc = forkRpc_;
        token = token_;
        tokenSystemAddress = tokenSystemAddress_;
        tokenCoreId = tokenCoreId_;
    }

    function setUp() public {
        uint256 forkId = vm.createFork(forkRpc);
        vm.selectFork(forkId);

        tokenBook = new TokenBook(address(this));

        tokenBook.addTokenInfo(token, TokenBook.TokenInfo(tokenSystemAddress, tokenCoreId));

        walletFactory = new HyperWalletFactory(address(this));
        user1Wallet = walletFactory.createWallet(user1);

        flashLoan = new FlashLoanModule(address(tokenBook), "FlashLoan", "1.0");
        walletFactory.toggleModule(address(flashLoan), true);

        vm.prank(user1);
        IHyperWallet(user1Wallet).toggleModule(address(flashLoan), true);

        spotBalancePrecompile = new MockSpotBalance();
        vm.etch(0x0000000000000000000000000000000000000801, address(spotBalancePrecompile).code);
        spotBalancePrecompile = MockSpotBalance(0x0000000000000000000000000000000000000801);

        coreUserExistsPrecompile = new MockCoreUserExists();
        vm.etch(0x0000000000000000000000000000000000000810, address(coreUserExistsPrecompile).code);
        coreUserExistsPrecompile = MockCoreUserExists(0x0000000000000000000000000000000000000810);

        // simulate enabling the wallet at core side
        coreUserExistsPrecompile.setCoreUserExists(user1Wallet, true);

        spotBalancePrecompile.setSpotBalance(user1Wallet, tokenCoreId, 100e8, 0, 0);
    }

    function testDeploy() external {
        assertEq(flashLoan.name(), "FlashLoan");
        assertEq(flashLoan.version(), "1.0");
    }

    function testDoFlashLoan() external {
        address recipient = address(0xABCD);
        uint64 amountToLoan = 1e8;
        deal(token, user1, amountToLoan);

        vm.startPrank(user1);
        vm.expectRevert(FlashLoanModule.NotAllowed.selector);
        flashLoan.doFlashLoan(user1Wallet, recipient, token, amountToLoan);

        ERC20(token).approve(address(flashLoan), amountToLoan);
        flashLoan.deposit(address(token), amountToLoan);

        uint256 recipientBalanceBefore = ERC20(token).balanceOf(recipient);
        flashLoan.doFlashLoan(user1Wallet, recipient, token, 1e8);
        uint256 recipientBalanceAfter = ERC20(token).balanceOf(recipient);

        assertEq(recipientBalanceAfter - recipientBalanceBefore, amountToLoan);
    }

    function testDepositWithdraw() external {
        uint64 amountToDeposit = 1e8;
        address user2 = address(0xAAAA);
        deal(token, user1, amountToDeposit);

        assertEq(flashLoan.deposits(token, user1), 0);

        vm.startPrank(user1);
        ERC20(token).approve(address(flashLoan), amountToDeposit);
        flashLoan.deposit(address(token), amountToDeposit);

        assertEq(flashLoan.deposits(token, user1), amountToDeposit);
        vm.stopPrank();

        vm.prank(user2);
        vm.expectRevert();
        flashLoan.withdraw(token, amountToDeposit);

        vm.prank(user1);
        flashLoan.withdraw(token, amountToDeposit);

        assertEq(flashLoan.deposits(token, user1), 0);
    }

    function testGetFlashLoan() external {
        uint64 amountToAsk = 1e8;
        deal(token, address(flashLoan), amountToAsk);
        bool result = flashLoan.getFlashLoan(user1Wallet, token, amountToAsk);
        assertEq(result, true);

        result = flashLoan.getFlashLoan(user1Wallet, token, amountToAsk * 2);
        assertEq(result, false);
    }
}

// add usdc as token
contract FlashLoanTestTestnet is
    FlashLoanTest(
        0xd9CBEC81df392A88AEff575E962d149d57F4d6bc,
        0x2000000000000000000000000000000000000000,
        0,
        "hl_testnet"
    )
{}
