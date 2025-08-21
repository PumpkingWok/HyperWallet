// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "./CoreWriterModule.sol";

/// @title CoreWriter SDK Module
/// @notice A high-level interface for interacting with core writer functionality
/// @author HyperWallet Labs
/// @dev Version 1.0
/// @dev Supported Action IDs:
///   1: Limit Order - Place limit orders for trading
///   2: Vault Transfer - Handle USD transfers between wallet and vault
///   3: Token Delegate - Manage token delegation to validators
///   4: Staking Deposit - Deposit HYPE for staking
///   5: Staking Withdraw - Withdraw HYPE staked tokens
///   6: Spot Send - Send tokens to other addresses
///   7: USD Class Transfer - Move USD between perpetual and core accounts
///   8: Finalize EVM Contract - Complete contract deployment process
///   9: Add API Wallet - Register new API wallets for automated trading
///   10: Cancel Order by OID - Cancel orders using order ID
///   11: Cancel Order by CLOID - Cancel orders using client order ID
contract CoreWriterSdkModule is CoreWriterModule {
    constructor(string memory name_, string memory version_) CoreWriterModule(name_, version_) {}

    /**
     * @notice Place a limit order for a given asset
     * @dev Action Id 1 - Creates a limit order with specified parameters
     * @param wallet The wallet address executing the order
     * @param asset Asset identifier
     * @param isBuy True for buy order, false for sell order
     * @param limitPx Limit price for the order
     * @param sz Order size
     * @param reduceOnly If true, the order will only reduce position size
     * @param encodedTif Time in force encoded value
     * @param cloid Client order ID
     */
    function limitOrder(
        address wallet,
        uint32 asset,
        bool isBuy,
        uint64 limitPx,
        uint64 sz,
        bool reduceOnly,
        uint8 encodedTif,
        uint128 cloid
    ) public virtual {
        bytes memory actionArgs = abi.encode(asset, isBuy, limitPx, sz, reduceOnly, encodedTif, cloid);
        bytes memory actionData = _encodeActionData(bytes1(0x01), bytes3(0x000001), actionArgs);
        _doAction(wallet, actionData);
    }

    /**
     * @notice Transfer USD between wallet and vault
     * @dev Action id 2 - Handles vault deposits and withdrawals
     * @param wallet The wallet address executing the transfer
     * @param vault The target vault address
     * @param isDeposit True for deposit to vault, false for withdrawal
     * @param usd Amount of USD to transfer
     */
    function vaultTransfer(address wallet, address vault, bool isDeposit, uint64 usd) public virtual {
        bytes memory actionArgs = abi.encode(vault, isDeposit, usd);
        bytes memory actionData = _encodeActionData(bytes1(0x01), bytes3(0x000002), actionArgs);
        _doAction(wallet, actionData);
    }

    /**
     * @notice Delegate or undelegate tokens to/from a validator
     * @dev Action id 3 - Manages token delegation to validators
     * @param wallet The wallet address executing the delegation
     * @param validator The validator address to delegate to/from
     * @param _wei Amount of tokens to delegate/undelegate
     * @param isUndelegate True to undelegate, false to delegate
     */
    function tokenDelegate(address wallet, address validator, uint64 _wei, bool isUndelegate) public virtual {
        bytes memory actionArgs = abi.encode(validator, _wei, isUndelegate);
        bytes memory actionData = _encodeActionData(bytes1(0x01), bytes3(0x000003), actionArgs);
        _doAction(wallet, actionData);
    }

    /**
     * @notice Deposit HYPE for staking
     * @dev Action id 4 - Handles hype staking deposits
     * @param wallet The wallet address executing the deposit
     * @param _wei Amount of tokens to stake
     */
    function stakingDeposit(address wallet, uint64 _wei) public virtual {
        bytes memory actionArgs = abi.encode(_wei);
        bytes memory actionData = _encodeActionData(bytes1(0x01), bytes3(0x000004), actionArgs);
        _doAction(wallet, actionData);
    }

    /**
     * @notice Withdraw hype staked tokens
     * @dev Action id 5 - Handles hype staking withdrawals
     * @param wallet The wallet address executing the withdrawal
     * @param _wei Amount of tokens to withdraw
     */
    function stakingWithdraw(address wallet, uint64 _wei) public virtual {
        bytes memory actionArgs = abi.encode(_wei);
        bytes memory actionData = _encodeActionData(bytes1(0x01), bytes3(0x000005), actionArgs);
        _doAction(wallet, actionData);
    }

    /**
     * @notice Send tokens to another address
     * @dev Action id 6 - Handles spot token transfers
     * @param wallet The wallet address executing the transfer
     * @param _destination The recipient address
     * @param token The token identifier to send
     * @param _wei Amount of tokens to send
     */
    function spotSend(address wallet, address _destination, uint64 token, uint64 _wei) public virtual {
        bytes memory actionArgs = abi.encode(_destination, token, _wei);
        bytes memory actionData = _encodeActionData(bytes1(0x01), bytes3(0x000006), actionArgs);
        _doAction(wallet, actionData);
    }

    /**
     * @notice Transfer USD between perpetual and core accounts
     * @dev Action id 7 - Handles USD class transfers between accounts
     * @param wallet The wallet address executing the transfer
     * @param ntl Amount to transfer in NTL units (6 decimals for both side)
     * @param toPerp True to transfer to perpetual account, false to transfer to core account
     */
    function usdClassTransfer(address wallet, uint64 ntl, bool toPerp) public virtual {
        bytes memory actionArgs = abi.encode(ntl, toPerp);
        bytes memory actionData = _encodeActionData(bytes1(0x01), bytes3(0x000007), actionArgs);
        _doAction(wallet, actionData);
    }

    /**
     * @notice Finalize an EVM contract deployment
     * @dev Action id 8 - Completes the contract deployment process
     * @param wallet The wallet address executing the finalization
     * @param token The token identifier associated with the contract
     * @param encodedFinalizeEvmContractVariant The encoded variant of finalization
     * @param createNonce The nonce used during contract creation
     */
    function finalizeEvmContract(
        address wallet,
        uint64 token,
        uint8 encodedFinalizeEvmContractVariant,
        uint64 createNonce
    ) public virtual {
        bytes memory actionArgs = abi.encode(token, encodedFinalizeEvmContractVariant, createNonce);
        bytes memory actionData = _encodeActionData(bytes1(0x01), bytes3(0x000008), actionArgs);
        _doAction(wallet, actionData);
    }

    /**
     * @notice Add a new API wallet
     * @dev Action id 9 - Registers a new API wallet for automated trading
     * @param wallet The wallet address executing the addition
     * @param apiWallet The address of the API wallet to add
     * @param apiWalletName The name to identify this API wallet
     */
    function addApiWallet(address wallet, address apiWallet, string memory apiWalletName) public virtual {
        bytes memory actionArgs = abi.encode(apiWallet, apiWalletName);
        bytes memory actionData = _encodeActionData(bytes1(0x01), bytes3(0x000009), actionArgs);
        _doAction(wallet, actionData);
    }

    /**
     * @notice Cancel an order using its order ID
     * @dev Action id 10 - Cancels a specific order by its unique order ID
     * @param wallet The wallet address executing the cancellation
     * @param asset The asset identifier of the order
     * @param oid The unique order ID to cancel
     */
    function cancelOrderByOid(address wallet, uint32 asset, uint64 oid) public virtual {
        bytes memory actionArgs = abi.encode(asset, oid);
        bytes memory actionData = _encodeActionData(bytes1(0x01), bytes3(0x00000A), actionArgs);
        _doAction(wallet, actionData);
    }

    /**
     * @notice Cancel an order using its client order ID
     * @dev Action id 11 - Cancels a specific order by its client order ID
     * @param wallet The wallet address executing the cancellation
     * @param asset The asset identifier of the order
     * @param cloid The client order ID to cancel
     */
    function cancelOrderByCloid(address wallet, uint32 asset, uint128 cloid) public virtual {
        bytes memory actionArgs = abi.encode(asset, cloid);
        bytes memory actionData = _encodeActionData(bytes1(0x01), bytes3(0x00000B), actionArgs);
        _doAction(wallet, actionData);
    }

    /**
     * @dev Internal helper function to encode the action data for core writer
     * @param version The version byte of the action protocol
     * @param actionId The 3-byte identifier of the action type
     * @param actionArgs The encoded arguments specific to the action
     * @return actionData The fully encoded action data ready for execution
     */
    function _encodeActionData(bytes1 version, bytes3 actionId, bytes memory actionArgs)
        internal
        pure
        returns (bytes memory actionData)
    {
        actionData = abi.encodePacked(version, actionId, actionArgs);
    }

    /// @dev Leave it empty to not allow arbitrary calls (TODO check if it is the best option)
    function doAction(address wallet, bytes memory actionData) external override {}

    /// @dev Leave it empty to not allow arbitrary calls
    function doAction(address wallet, bytes1 version, bytes3 actionId, bytes memory actionArgs) external override {}

    /// @dev Leave it empty to not allow arbitrary calls
    function doActions(address hyperWallet, bytes[] memory actionsData) external override {}
}
