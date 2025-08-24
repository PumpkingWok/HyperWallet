// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "../coreWriter/CoreWriterSdkModule.sol";
import {SafeTransferLib} from "solady/utils/SafeTransferLib.sol";
import {ERC20} from "solady/tokens/ERC20.sol";
import {ITokenBook} from "../../interfaces/ITokenBook.sol";

/// @title FlashLoan Module
/// @notice A module that enables flash loans within the same EVM block by leveraging HyperCore spot balances.
/// Flash loans are only available to wallet who have sufficient balance in their Core spot account.
/// The mechanism works as follows:
/// 1. Wallet requests a flash loan for amount X of token
/// 2. Module checks if wallet has >= amount X in their Core spot balance
/// 3. If valid, and there is enough amount of token here in the module, user receives amount X on EVM side immediately
/// 4. The equivalent amount is moved from wallet's Core spot to module core spot
/// 5. Module sends amount to system address to trigger repayment
/// 6. Funds are automatically returned to the module from Core at least in the next EVM block
/// @author HyperWallet Labs
contract FlashLoanModule is CoreWriterSdkModule {
    /// @dev token info book
    ITokenBook public immutable TOKEN_BOOK;

    /// @dev Throwed at auth
    error NotAllowed();

    event Deposit(address user, address token, uint64 amount);

    /// @dev Emitted when a flash loan is executed
    event FlashLoan(address wallet, address recipient, address token, uint64 amount);

    event Withdraw(address user, address token, uint64 amount);

    /// token => user => amount
    mapping(address => mapping(address => uint64)) public deposits;

    constructor(address tokenBook_, string memory name_, string memory version_) CoreWriterSdkModule(name_, version_) {
        TOKEN_BOOK = ITokenBook(tokenBook_);
    }

    /**
     * @dev ask a flash loan to be repaid in the next evm block
     * @param hyperWallet Wallet to ask the flashloan for
     * @param recipient address to send the amount
     * @param token token to borrow
     * @param amount amount to borrow
     */
    function doFlashLoan(address hyperWallet, address recipient, address token, uint64 amount) external {
        _doFlashLoan(hyperWallet, recipient, token, amount);
    }

    /**
     * @dev ask a flash loan to be repaid in the next evm block
     * @param hyperWallet Wallet to ask the flashloan for (recipient too)
     * @param token token to borrow
     * @param amount amount to borrow
     */
    function doFlashLoan(address hyperWallet, address token, uint64 amount) external {
        _doFlashLoan(hyperWallet, hyperWallet, token, amount);
    }

    /**
     * @dev ask a flash loan to be repaid in the next evm block
     * @param hyperWallet Wallet to ask the flashloan for
     * @param recipient address to send the amount
     * @param token token to borrow
     * @param amount amount to borrow
     */
    function _doFlashLoan(address hyperWallet, address recipient, address token, uint64 amount)
        internal
        onlyEnabledWallet(hyperWallet)
        onlyHyperWalletOwnerOrAllowed(hyperWallet)
    {
        // fetch the token id at core spot
        ITokenBook.TokenInfo memory tokenInfo = TOKEN_BOOK.getTokenInfoByEvmAddress(token);
        uint64 tokenIdCoreSpot = tokenInfo.tokenIdCoreSpot;

        // check if a flash loan can requested
        if (!_getFlashLoan(hyperWallet, token, tokenIdCoreSpot, amount)) revert NotAllowed();

        // send amount to the wallet
        ERC20(token).transfer(recipient, amount);

        // send amount from wallet to the module at core spot
        spotSend(hyperWallet, address(this), tokenIdCoreSpot, amount);

        // send module amount to systemAddress at core, to receive back to evm
        _spotSend(tokenInfo.systemAddress, tokenIdCoreSpot, amount);

        emit FlashLoan(hyperWallet, recipient, token, amount);
    }

    /**
     * @dev Simulate a loan request, return true is it can be done
     * @param hyperWallet Wallet to ask the flashloan for
     * @param token token to borrow
     * @param amount amount to borrow
     */
    function getFlashLoan(address hyperWallet, address token, uint64 amount) external view returns (bool) {
        ITokenBook.TokenInfo memory tokenInfo = TOKEN_BOOK.getTokenInfoByEvmAddress(token);
        return _getFlashLoan(hyperWallet, token, tokenInfo.tokenIdCoreSpot, amount);
    }

    /**
     * @dev Internal function to check if a loan is feasible for the wallet
     * @param hyperWallet Wallet to ask the flashloan for
     * @param token Token to borrow
     * @param tokenIdCoreSpot Token id at core spot
     * @param amount Amount to borrow
     */
    function _getFlashLoan(address hyperWallet, address token, uint64 tokenIdCoreSpot, uint64 amount)
        internal
        view
        returns (bool)
    {
        L1Read.SpotBalance memory spotBalance = L1Read.spotBalance(hyperWallet, tokenIdCoreSpot);
        if (spotBalance.total < amount) return false;

        // check the module token balance
        if (ERC20(token).balanceOf(address(this)) < amount) return false;

        return true;
    }

    /**
     * @dev Deposit a token to be used in flashloan
     * @param token Token to deposit
     * @param amount Amount to deposit
     */
    function deposit(address token, uint64 amount) external {
        SafeTransferLib.safeTransferFrom(token, msg.sender, address(this), amount);
        deposits[token][msg.sender] += amount;
    }

    /**
     * @dev Withdraw a token
     * @param token Token to withdraw
     * @param amount Amount to withdraw
     */
    function withdraw(address token, uint64 amount) external {
        deposits[token][msg.sender] -= amount;
        SafeTransferLib.safeTransfer(token, msg.sender, amount);
    }

    /**
     * @dev Internal function to send spot token from the module address to the wallet
     * @param hyperWallet Wallet to send spot token at core
     * @param coreTokenId Token id at core spot
     * @param amount Amount to send
     */
    function _spotSend(address hyperWallet, uint64 coreTokenId, uint64 amount) internal {
        // send the same amount to the user's core spot wallet
        bytes memory actionArgs = abi.encode(hyperWallet, coreTokenId, amount);
        // version 1 action id 6 SendSpot
        bytes memory data = abi.encodePacked(bytes1(0x01), bytes3(0x000006), actionArgs);
        CORE_WRITER.sendRawAction(data);
    }
}
