// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "../Module.sol";
import {SafeTransferLib} from "solady/utils/SafeTransferLib.sol";
import {ERC20} from "solady/tokens/ERC20.sol";
import {ICoreWriter} from "../../interfaces/ICoreWriter.sol";

/// @title Enabler Module
/// @notice Module for enabling wallets on the core system with required token deposits
/// @author HyperWallet Labs
/// @dev This module handles the wallet activation process on core by:
///   - Getting from user 0.0001 HYPE and 1 USDC (hyperliquid fee on wallet activation) on evm
///   - Sending 0.0001 HYPE to the user's wallet on core spot, 1 USDC will be lost as fee.
/// @dev Core Actions Used:
///   - Action ID 6: SendSpot - Used to send tokens to wallets on core side
/// @dev Security Features:
///   - One action per block limit
///   - Balance verification before token transfers
///   - Recipient-only access for token retrieval
///   - Assumes spot amounts sent in previous block are correctly fetchable by next EVM block
contract EnablerModule is Module {
    /// @dev hype token id at core spot
    uint64 public immutable HYPE_CORE_TOKEN_ID;

    /// @dev hype amount used to enable the wallet at core with evm decimals
    uint64 public constant HYPE_ENABLER_AMOUNT_EVM = 1e14; // 0.0001 HYPE (18 decimals)

    /// @dev hype amount used to enable the wallet at core with core decimals
    uint64 public constant HYPE_ENABLER_AMOUNT_CORE = 1e4; // 0.0001 HYPE (8 decimals)

    uint64 public constant USDC_CORE_TO_EVM_FEE = 2e3; // 0.0002 HYPE (8 decimals)

    /// @dev usdc token id at core spot
    uint64 public immutable USDC_CORE_TOKEN_ID;

    /// @dev usdc amount used to enable the wallet at core
    uint64 public constant USDC_ENABLER_AMOUNT = 1e8; // 1 USDC

    /// @dev hype system address
    address public constant HYPE_SYSTEM_ADDRESS = 0x2222222222222222222222222222222222222222;

    /// @dev usdc system address
    address public immutable USDC_SYSTEM_ADDRESS;

    /// @dev recipient used to receive funds
    address public immutable RECIPIENT;

    /// @dev usdc token
    address public immutable USDC;

    /// @dev hyperliquid core writer
    ICoreWriter public constant CORE_WRITER = ICoreWriter(0x3333333333333333333333333333333333333333);

    /// @dev last block action
    uint256 public lastBlockAction = block.number;

    ///////////////
    // Errors //
    ///////////////

    /// @dev Thrown when trying to perform actions too quickly between blocks
    error LowerIdleTime();

    /// @dev Thrown when attempting to use more tokens than available in the balance
    error NotEnoughAmount();

    /// @dev Thrown when trying to perform more than one action per block
    error OneActionPerBlock();

    /// @dev Thrown when a function is called by an unauthorized address
    error NotAllowed();

    /// @dev Thrown when the spot token transfer operation fails on core side
    error SendSpotFailed();

    /// @dev Thrown when attempting to enable a wallet that is already enabled on core
    error WalletAlreadyEnabled();

    /// @dev Thrown when the provided HYPE amount doesn't match the required enabler amount
    error WrongHypeAmount();

    /// @dev Emitted when a wallet is successfully enabled on core
    /// @param hyperWallet The address of the wallet that was enabled
    event WalletEnabled(address hyperWallet);

    constructor(
        uint64 hypeCoreTokenId_,
        uint64 usdcCoreTokenId_,
        address usdcSystemAddress_,
        address usdc_,
        address recipient_,
        string memory name_,
        string memory version_
    ) Module(name_, version_) {
        HYPE_CORE_TOKEN_ID = hypeCoreTokenId_;
        USDC_CORE_TOKEN_ID = usdcCoreTokenId_;
        USDC_SYSTEM_ADDRESS = usdcSystemAddress_;
        USDC = usdc_;
        RECIPIENT = recipient_;
    }

    /**
     * @notice Enable a wallet on core by depositing required HYPE and USDC
     * @dev Uses Action ID 6 (SendSpot) to transfer tokens to core
     * @dev At the end of this function, this contract will not hold any HYPE or USDC
     * @param hyperWallet The wallet address to enable on core
     * @custom:throws WalletAlreadyEnabled if wallet is already enabled
     * @custom:throws WrongHypeAmount if msg.value doesn't match HYPE_ENABLER_AMOUNT_EVM
     * @custom:throws NotEnoughAmount if insufficient HYPE or USDC balance
     * @custom:throws OneActionPerBlock if another action was performed in the same block
     */
    function enableWalletOnCore(address hyperWallet)
        external
        payable
        onlyHyperWalletOwnerOrAllowed(hyperWallet)
        oneActionPerBlock
    {
        // check if the wallet already exists at core
        L1Read.CoreUserExists memory coreUserExists = L1Read.coreUserExists(hyperWallet);
        if (coreUserExists.exists) revert WalletAlreadyEnabled();

        // check if the hype amount pass is correct
        if (msg.value != HYPE_ENABLER_AMOUNT_EVM) revert WrongHypeAmount();

        // check if at core side there is enough amount in HYPE and 1 USDC as fee required to enable it the first time
        L1Read.SpotBalance memory hypeSpotBalance = L1Read.spotBalance(address(this), HYPE_CORE_TOKEN_ID);
        L1Read.SpotBalance memory usdcSpotBalance = L1Read.spotBalance(address(this), USDC_CORE_TOKEN_ID);
        if (hypeSpotBalance.total < HYPE_ENABLER_AMOUNT_CORE) revert NotEnoughAmount();
        if (usdcSpotBalance.total < USDC_ENABLER_AMOUNT) revert NotEnoughAmount();

        // transfer USDC here
        SafeTransferLib.safeTransferFrom(USDC, msg.sender, address(this), USDC_ENABLER_AMOUNT);
        // transfer USDC to core
        SafeTransferLib.safeTransfer(USDC, USDC_SYSTEM_ADDRESS, USDC_ENABLER_AMOUNT);

        // transfer hype and usdc to the system addresses to receive on core
        payable(HYPE_SYSTEM_ADDRESS).transfer(HYPE_ENABLER_AMOUNT_EVM);
        _sendSpot(hyperWallet, HYPE_CORE_TOKEN_ID, HYPE_ENABLER_AMOUNT_CORE);

        emit WalletEnabled(hyperWallet);
    }

    /**
     * @notice Retrieve tokens used to bootstrap the module from core side
     * @dev Uses Action ID 6 (SendSpot) to transfer tokens back to system addresses
     * @dev Only callable by the designated recipient address
     * @custom:throws NotAllowed if caller is not the recipient
     * @custom:throws OneActionPerBlock if another action was performed in the same block
     */
    function retrieveTokenFromCore() external oneActionPerBlock {
        if (msg.sender != RECIPIENT) revert NotAllowed();

        // bridge all HYPE and USDC to evm
        L1Read.SpotBalance memory hypeSpotBalance = L1Read.spotBalance(address(this), HYPE_CORE_TOKEN_ID);
        L1Read.SpotBalance memory usdcSpotBalance = L1Read.spotBalance(address(this), USDC_CORE_TOKEN_ID);

        // it charges fee in HYPE (default fee 0.00002 HYPE) to send USDC from core to evm
        // zero fee to send hype from core to evm
        if (usdcSpotBalance.total != 0 && hypeSpotBalance.total > USDC_CORE_TO_EVM_FEE) {
            _sendSpot(USDC_SYSTEM_ADDRESS, USDC_CORE_TOKEN_ID, usdcSpotBalance.total);
            _sendSpot(HYPE_SYSTEM_ADDRESS, HYPE_CORE_TOKEN_ID, hypeSpotBalance.total - USDC_CORE_TO_EVM_FEE);
        }
    }

    /**
     * @notice Transfer tokens received from core to the designated recipient
     * @dev Transfers both HYPE (native) and USDC tokens to the recipient address
     * @dev The recipient address is set during contract deployment
     * @dev Any address can call it
     */
    function transferTokensToRecipient() external {
        uint256 hypeBalance = address(this).balance;
        uint256 usdcBalance = ERC20(USDC).balanceOf(address(this));

        if (hypeBalance != 0) payable(RECIPIENT).transfer(hypeBalance);
        if (usdcBalance != 0) SafeTransferLib.safeTransfer(USDC, RECIPIENT, usdcBalance);
    }

    /**
     * @notice Internal function to send spot tokens on core side
     * @dev Uses Action ID 6 (SendSpot) to transfer tokens to a specified wallet
     * @param hyperWallet The recipient wallet address on core
     * @param coreTokenId The token identifier on core
     * @param amount The amount to send (in core decimals)
     * @custom:throws SendSpotFailed if the core transfer fails
     */
    function _sendSpot(address hyperWallet, uint64 coreTokenId, uint64 amount) internal {
        // send the same amount to the user's core spot wallet
        bytes memory actionArgs = abi.encode(hyperWallet, coreTokenId, amount);
        // version 1 action id 6 SendSpot
        bytes memory data = abi.encodePacked(bytes1(0x01), bytes3(0x000006), actionArgs);
        CORE_WRITER.sendRawAction(data);
    }

    /**
     * @notice Internal function to check if there was another action in the same block
     */
    function _oneActionPerBlock() internal {
        if (block.number > lastBlockAction) {
            lastBlockAction = block.number;
        } else {
            revert OneActionPerBlock();
        }
    }

    /**
     * @notice Ensures only one action can be performed per block
     * @dev Tracks the last block number where an action was performed
     * @dev Uses unchecked for gas optimization since block.number overflow is impossible
     */
    modifier oneActionPerBlock() {
        _oneActionPerBlock();
        _;
    }
}
