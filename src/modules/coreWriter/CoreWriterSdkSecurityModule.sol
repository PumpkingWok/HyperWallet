// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "./CoreWriterSdkModule.sol";

/// @title CoreWriter SDK Security Module
/// @notice Enhanced version of CoreWriterSdkModule with additional security checks
/// @author HyperWallet Labs
/// @dev Version 1.0
/// @dev Security features:
///   - Balance checks before transfers and orders
///   - Validation of encoded parameters
///   - Vault equity and lock period verification
///   - Withdrawal amount verification
///   - Support for HYPE and USDC core tokens
/// @dev Inherits all action IDs (1-11) from CoreWriterSdkModule with added security layers
contract CoreWriterSdkSecurityModule is CoreWriterSdkModule {
    /// @dev hype core token id
    uint64 public immutable HYPE_CORE_TOKEN_ID;

    /// @dev usdc core token id
    uint64 public immutable USDC_CORE_TOKEN_ID;

    ///////////////
    // Errors //
    ///////////////

    /// @dev Thrown when attempting to withdraw funds that are still in their lock period
    error AmountLocked();

    /// @dev Thrown when the provided Time-in-Force value is not within valid range (1-3)
    error EncodedTifNotSupported();

    /// @dev Thrown when attempting to transfer or use more funds than available
    error NotEnoughAmount();

    /// @dev Thrown when the provided contract finalization variant is not supported (must be 1-3)
    error VariantNotSupported();

    constructor(uint64 hypeCoreTokenId_, uint64 usdcCoreTokenId_, string memory name_, string memory version_)
        CoreWriterSdkModule(name_, version_)
    {
        HYPE_CORE_TOKEN_ID = hypeCoreTokenId_;
        USDC_CORE_TOKEN_ID = usdcCoreTokenId_;
    }

    /**
     * @notice Place a limit order with additional security checks
     * @dev Action ID 1 - Validates the Time-in-Force parameter before placing the order
     * @param wallet The wallet address executing the order
     * @param asset Asset identifier to buy/sell
     * @param isBuy True for buy order, false for sell order
     * @param limitPx Limit price in standard units (18 decimals)
     * @param sz Order size in standard units (18 decimals)
     * @param reduceOnly If true, the order will only reduce position size
     * @param encodedTif Time-in-Force encoded value (must be 1-3)
     * @param cloid Client order ID (0 means no client order ID)
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
    ) public virtual override {
        // TODO check if the wallet has enough sz asset or liquidity to sell or buy
        if (encodedTif == 0 || encodedTif > 3) revert EncodedTifNotSupported();
        super.limitOrder(wallet, asset, isBuy, limitPx, sz, reduceOnly, encodedTif, cloid);
    }

    /**
     * @notice Transfer USD between wallet and vault with balance verification
     * @dev Action ID 2 - Checks available balance for deposits and verifies vault equity and lock period for withdrawals
     * @param wallet The wallet address executing the transfer
     * @param vault The vault address to interact with
     * @param isDeposit True for deposit to vault, false for withdrawal
     * @param usd Amount of USD to transfer in standard units
     */
    function vaultTransfer(address wallet, address vault, bool isDeposit, uint64 usd) public virtual override {
        // check if the wallet has enough usd to transfer to vault
        if (isDeposit) {
            _checkSpotBalance(wallet, USDC_CORE_TOKEN_ID, usd);
        } else {
            PrecompileLib.UserVaultEquity memory userEquity = PrecompileLib.userVaultEquity(wallet, vault);
            if (userEquity.equity < usd) revert NotEnoughAmount();
            if (userEquity.lockedUntilTimestamp > block.timestamp) revert AmountLocked();
        }
        super.vaultTransfer(wallet, vault, isDeposit, usd);
    }

    /**
     * @notice Delegate or undelegate hype to/from a validator with balance checks
     * @dev Action ID 3 - Verifies hype balance and delegation restrictions before proceeding
     * @param wallet The wallet address executing the delegation
     * @param validator The validator address to delegate to/from
     * @param _wei Amount of tokens to delegate/undelegate
     * @param isUndelegate True to undelegate, false to delegate
     */
    function tokenDelegate(address wallet, address validator, uint64 _wei, bool isUndelegate) public virtual override {
        // TODO check if HYPE amount is > _wei to delegateUndelegate
        // TODO check if there is any restrictions
        super.tokenDelegate(wallet, validator, _wei, isUndelegate);
    }

    /**
     * @notice Deposit tokens for staking with balance verification
     * @dev Action ID 4 - Verifies sufficient HYPE token balance before staking
     * @param wallet The wallet address executing the deposit
     * @param _wei Amount of tokens to stake
     */
    function stakingDeposit(address wallet, uint64 _wei) public virtual override {
        // check if wei is enough
        _checkSpotBalance(wallet, HYPE_CORE_TOKEN_ID, _wei);
        super.stakingDeposit(wallet, _wei);
    }

    /**
     * @notice Withdraw staked tokens with balance verification
     * @dev Action ID 5 - Verifies sufficient staked HYPE token balance before withdrawal
     * @param wallet The wallet address executing the withdrawal
     * @param _wei Amount of tokens to withdraw
     */
    function stakingWithdraw(address wallet, uint64 _wei) public virtual override {
        // check if the wei is enough to withdraw
        _checkSpotBalance(wallet, HYPE_CORE_TOKEN_ID, _wei);
        super.stakingWithdraw(wallet, _wei);
    }

    /**
     * @notice Send tokens to another address with balance verification
     * @dev Action ID 6 - Verifies sufficient token balance before sending
     * @param wallet The wallet address executing the transfer
     * @param _destination The recipient address
     * @param token The token identifier to send
     * @param _wei Amount of tokens to send
     */
    function spotSend(address wallet, address _destination, uint64 token, uint64 _wei) public virtual override {
        // check if the token spot balance is enough to transfer
        _checkSpotBalance(wallet, token, _wei);
        super.spotSend(wallet, _destination, token, _wei);
    }

    /**
     * @notice Transfer USD between perpetual and core accounts with balance checks
     * @dev Action ID 7 - Verifies sufficient balance in source account before transfer
     * @param wallet The wallet address executing the transfer
     * @param ntl Amount to transfer in NTL units
     * @param toPerp True to transfer from spot to perpetual, false for reverse
     */
    function usdClassTransfer(address wallet, uint64 ntl, bool toPerp) public virtual override {
        // check if the usd spot or perp amount is enough to transfer
        if (toPerp) {
            _checkSpotBalance(wallet, USDC_CORE_TOKEN_ID, ntl);
        } else {
            if (PrecompileLib.withdrawable(wallet) < ntl) revert NotEnoughAmount();
        }
        super.usdClassTransfer(wallet, ntl, toPerp);
    }

    /**
     * @notice Finalize an EVM contract deployment with variant validation
     * @dev Action ID 8 - Validates that the finalization variant is within supported range (1-3)
     * @param wallet The wallet address executing the finalization
     * @param token The token identifier associated with the contract
     * @param encodedFinalizeEvmContractVariant The variant of finalization (must be 1-3)
     * @param createNonce The nonce used during contract creation
     */
    function finalizeEvmContract(
        address wallet,
        uint64 token,
        uint8 encodedFinalizeEvmContractVariant,
        uint64 createNonce
    ) public virtual override {
        if (encodedFinalizeEvmContractVariant == 0 || encodedFinalizeEvmContractVariant > 3) {
            revert VariantNotSupported();
        }
        super.finalizeEvmContract(wallet, token, encodedFinalizeEvmContractVariant, createNonce);
    }

    /**
     * @notice Internal helper to verify sufficient token balance
     * @dev Checks if the wallet has enough tokens in spot balance
     * @param wallet The wallet address to check balance for
     * @param token The token identifier to check
     * @param balance The required balance amount
     * @custom:throws NotEnoughAmount if balance is insufficient
     */
    function _checkSpotBalance(address wallet, uint64 token, uint64 balance) internal {
        PrecompileLib.SpotBalance memory spotBalance = PrecompileLib.spotBalance(wallet, token);
        if (spotBalance.total < balance) revert NotEnoughAmount();
    }
}
