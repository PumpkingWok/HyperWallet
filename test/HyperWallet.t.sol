pragma solidity ^0.8.18;

import "forge-std/Test.sol";

import "../src/HyperWalletFactory.sol";
import {IHyperWallet} from "../src/interfaces/IHyperWallet.sol";
import {ERC20} from "solady/tokens/ERC20.sol";

contract HyperWalletTest is Test {
    HyperWalletFactory factory;

    address user1 = address(0xABCD);
    IHyperWallet hwUser1;
    ERC20 token = ERC20(0xd9CBEC81df392A88AEff575E962d149d57F4d6bc);
    address tokenSystemAddress = 0x2000000000000000000000000000000000000000;

    function setUp() public {
        uint256 forkId = vm.createFork("hl_testnet");
        vm.selectFork(forkId);

        factory = new HyperWalletFactory(address(this));
        address wallet = factory.createWallet(user1);
        hwUser1 = IHyperWallet(wallet);

        factory.setSystemAddress(address(token), tokenSystemAddress);

        deal(user1, 1e18);
        deal(address(token), user1, 1e8);
    }

    function testDeploy() external {
        assertEq(hwUser1.walletId(), 0);
        assertEq(hwUser1.FACTORY(), address(factory));
        assertEq(hwUser1.lastActionBlock(), 0);
    }

    function testTransferHypeToCore() external {
        uint256 hypeToTransfer = 1e18;
        address hypeSystemAddress = hwUser1.HYPE_SYSTEM_ADDRESS();

        uint256 hypeUserBalanceBefore = user1.balance;
        uint256 hypeSABalanceBefore = hypeSystemAddress.balance;

        vm.prank(user1);
        hwUser1.transferHypeToCoreSpot{value: hypeToTransfer}();

        uint256 hypeUserBalanceAfter = user1.balance;
        uint256 hypeSABalanceAfter = hypeSystemAddress.balance;

        assertEq(hypeUserBalanceBefore - hypeUserBalanceAfter, hypeToTransfer);
        assertEq(hypeSABalanceAfter - hypeSABalanceBefore, hypeToTransfer);
    }

    function testTransferHypeToCoreViaReceive() external {
        uint256 hypeToTransfer = 1e18;
        (bool result,) = payable(address(hwUser1)).call{value: hypeToTransfer}("");

        assertEq(result, true);
    }

    function testTransferTokenToCore() external {
        uint256 amountToTransfer = 1e8;

        uint256 tokenUserBalanceBefore = token.balanceOf(user1);
        uint256 tokenSABalanceBefore = token.balanceOf(tokenSystemAddress);

        vm.startPrank(user1);
        token.approve(address(hwUser1), amountToTransfer);
        hwUser1.transferTokenToCoreSpot(address(token), amountToTransfer);

        uint256 tokenUserBalanceAfter = token.balanceOf(user1);
        uint256 tokenSABalanceAfter = token.balanceOf(tokenSystemAddress);

        assertEq(tokenUserBalanceBefore - tokenUserBalanceAfter, amountToTransfer);
        assertEq(tokenSABalanceAfter - tokenSABalanceBefore, amountToTransfer);
    }

    function testTransferTokenNotSupported() external {
        address dummyToken = address(0xABBBA);
        vm.expectRevert(HyperWallet.TokenNotSupported.selector);
        hwUser1.transferTokenToCoreSpot(dummyToken, 1e18);
    }

    function testWithdraw() external {
        uint256 amountToWithdraw = 1e8;
        deal(address(token), address(hwUser1), amountToWithdraw);

        uint256 userBalanceBefore = token.balanceOf(user1);
        vm.prank(user1);
        hwUser1.withdraw(address(token), amountToWithdraw, user1);
        uint256 hwBalance = token.balanceOf(address(hwUser1));
        uint256 userBalanceAfter = token.balanceOf(user1);

        assertEq(hwBalance, 0);
        assertEq(userBalanceAfter - userBalanceBefore, amountToWithdraw);
    }

    function testEnableDisableModule() external {
        address module = address(0xABCD);
        vm.expectRevert(HyperWallet.ModuleNotActive.selector);
        // enable only on wallet
        _toggleModule(module, true, false);

        // enable in both factory and wallet
        _toggleModule(module, true, true);

        assertEq(hwUser1.modules(module), true);

        // disable on wallet
        _toggleModule(module, false, false);

        assertEq(hwUser1.modules(module), false);
    }

    function testDoAction() external {
        address module = address(0xABCD);
        address moduleNotEnabled = address(0xABBCD);
        // enable in both factory and wallet
        _toggleModule(module, true, true);

        address destination;
        bytes memory action;
        vm.prank(module);
        hwUser1.doAction(destination, action);

        // test ModuleNotEnabled error
        vm.roll(block.number + 1);
        vm.startPrank(moduleNotEnabled);
        vm.expectRevert(HyperWallet.ModuleNotEnabled.selector);
        hwUser1.doAction(destination, action);
    }

    function testDoActions() external {
        address module = address(0xABCD);
        // enable in both factory and wallet
        _toggleModule(module, true, true);

        address destination;
        bytes[] memory actions = new bytes[](3);
        vm.prank(module);
        hwUser1.doActions(destination, actions);
    }

    function testOneActionPerBlock() external {
        address module = address(0xABCD);
        _toggleModule(module, true, true);

        address destination;
        bytes memory action;

        vm.startPrank(module);
        hwUser1.doAction(destination, action);

        vm.expectRevert(HyperWallet.BlockAlreadyUsed.selector);
        hwUser1.doAction(destination, action);
    }

    function testSetAllowance() external {
        address module = address(0xABCD);
        address allowed = address(0xABBB);
        vm.prank(user1);
        hwUser1.toggleAllowance(module, allowed, true);

        assertEq(hwUser1.allowance(module, allowed), true);

        // test OnlyNftHolder error
        vm.expectRevert(HyperWallet.NotNftHolder.selector);
        hwUser1.toggleAllowance(module, allowed, false);
    }

    function testTransferOwnership() external {
        address newOwner = address(0xABBB);
        vm.prank(user1);
        factory.transferFrom(user1, newOwner, 0);

        vm.prank(user1);
        vm.expectRevert(HyperWallet.NotNftHolder.selector);
        hwUser1.toggleAllowance(address(0xABBB), address(0xABCD), true);

        vm.prank(newOwner);
        hwUser1.toggleAllowance(address(0xABBB), address(0xABCD), true);
    }

    function _toggleModule(address module, bool walletStatus, bool enableOnFactory) internal {
        if (enableOnFactory) {
            factory.toggleModule(module, enableOnFactory);
        }

        vm.prank(user1);
        hwUser1.toggleModule(module, walletStatus);
    }
}
