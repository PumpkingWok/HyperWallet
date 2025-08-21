// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {IHyperWallet} from "../interfaces/IHyperWallet.sol";
import {IERC721} from "openzeppelin/token/ERC721/IERC721.sol";
import {L1Read} from "../utils/L1Read.sol";

/// @notice abstract core module
/// @author HyperWallet Labs
abstract contract Module {
    /// @dev module name
    string private _name;

    /// @dev module version
    string private _version;

    ///////////////
    // Errors //
    ///////////////

    /// @dev Thrown if the msg.sender is not the owner nor allowed.
    error OnlyHyperWalletOwnerOrAllowed();

    /// @dev Thrown if the wallet is not enabled at core.
    error WalletNotEnabled();

    constructor(string memory name_, string memory version_) {
        _name = name_;
        _version = version_;
    }

    /**
     * @notice Get the module name
     */
    function name() external view virtual returns (string memory) {
        return _name;
    }

    /**
     * @notice Get the module version
     */
    function version() external view virtual returns (string memory) {
        return _version;
    }

    /**
     * @notice Function to check if the msg.sender is the hw owner or allowed
     * @param hyperWallet Wallet to check
     */
    function _onlyHyperWalletOwnerOrAllowed(address hyperWallet) internal view {
        IHyperWallet wallet = IHyperWallet(hyperWallet);
        address hyperWalletFactory = wallet.FACTORY();
        address hyperWalletOwner = IERC721(hyperWalletFactory).ownerOf(wallet.walletId());
        if (msg.sender != hyperWalletOwner && !wallet.allowance(address(this), msg.sender)) {
            revert OnlyHyperWalletOwnerOrAllowed();
        }
    }

    /**
     * @notice Function to check if wallet is enabled at core side
     * @param hyperWallet Wallet to check
     */
    function _onlyEnabledWallet(address hyperWallet) internal view {
        // check if the wallet already exists at core
        L1Read.CoreUserExists memory coreUserExists = L1Read.coreUserExists(hyperWallet);
        if (!coreUserExists.exists) revert WalletNotEnabled();
    }

    /**
     * @dev Modifier to restrict function access to wallet owner or allowed addresses
     * @param hyperWallet The address of the HyperWallet contract to check permissions for
     */
    modifier onlyHyperWalletOwnerOrAllowed(address hyperWallet) {
        _onlyHyperWalletOwnerOrAllowed(hyperWallet);
        _;
    }

    /**
     * @dev Modifier to ensure the wallet is enabled at core level
     * @param hyperWallet The address of the HyperWallet contract to check enabled status
     */
    modifier onlyEnabledWallet(address hyperWallet) {
        _onlyEnabledWallet(hyperWallet);
        _;
    }
}
