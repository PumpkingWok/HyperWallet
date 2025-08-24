// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {ICoreWriter} from "../../interfaces/ICoreWriter.sol";
import {IHyperWallet} from "../../interfaces/IHyperWallet.sol";
import "../Module.sol";

/// @title CoreWriter Module
/// @notice A foundational module for interacting with Hyperliquid's core writer contract
/// @author HyperWallet Labs
contract CoreWriterModule is Module {
    /// @dev hyperliquid core writer
    ICoreWriter constant CORE_WRITER = ICoreWriter(0x3333333333333333333333333333333333333333);

    /// @dev Emitted when an action is successfully executed through the core writer
    /// @param hyperWallet The address of the HyperWallet that executed the action
    /// @param actionData The raw action data that was executed
    event ActionExecuted(address hyperWallet, bytes actionData);

    constructor(string memory name_, string memory version_) Module(name_, version_) {}

    /**
     * @notice Execute a single raw action through the core writer
     * @dev This function allows executing arbitrary action data
     * @param hyperWallet The address of the HyperWallet to execute the action from
     * @param actionData The raw action data to be executed
     */
    function doAction(address hyperWallet, bytes memory actionData) external virtual {
        _doAction(hyperWallet, actionData);
    }

    /**
     * @notice Execute a single action with structured parameters through the core writer
     * @dev This function constructs the action data from version, id, and args
     * @param hyperWallet The address of the HyperWallet to execute the action from
     * @param _version The version byte of the action
     * @param actionId The 3-byte identifier of the action
     * @param actionArgs The encoded arguments for the action
     */
    function doAction(address hyperWallet, bytes1 _version, bytes3 actionId, bytes memory actionArgs)
        external
        virtual
    {
        bytes memory actionData = abi.encodePacked(_version, actionId, actionArgs);
        _doAction(hyperWallet, actionData);
    }

    /**
     * @notice Execute multiple actions in a batch through the core writer
     * @dev This function executes multiple actions in sequence
     * @param hyperWallet The address of the HyperWallet to execute the actions from
     * @param actionsData Array of raw action data to be executed
     */
    function doActions(address hyperWallet, bytes[] memory actionsData) external virtual {
        bytes[] memory sendDatas = new bytes[](actionsData.length);
        for (uint256 i = 0; i < actionsData.length; i++) {
            sendDatas[i] = abi.encodeWithSignature("sendRawAction(bytes)", actionsData[i]);

            emit ActionExecuted(hyperWallet, actionsData[i]);
        }
        IHyperWallet(hyperWallet).doActions(address(CORE_WRITER), sendDatas);
    }

    /**
     * @notice Internal function to execute an action through the core writer
     * @dev Validates module status and permissions before executing
     * @param hyperWallet The address of the HyperWallet to execute the action from
     * @param actionData The raw action data to be executed
     */
    function _doAction(address hyperWallet, bytes memory actionData)
        internal
        virtual
        onlyHyperWalletOwnerOrAllowed(hyperWallet)
    {
        bytes memory sendData = abi.encodeWithSignature("sendRawAction(bytes)", actionData);
        IHyperWallet(hyperWallet).doAction(address(CORE_WRITER), sendData);

        // Emit event after successful execution
        emit ActionExecuted(hyperWallet, actionData);
    }
}
