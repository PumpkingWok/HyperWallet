// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Clones} from "openzeppelin/proxy/Clones.sol";
import {HyperWallet} from "./HyperWallet.sol";
import "openzeppelin/token/ERC721/ERC721.sol";
import "openzeppelin/access/Ownable2Step.sol";

/// @notice HyperWallet factory
/// @author HyperWallet
contract HyperWalletFactory is Ownable2Step, ERC721 {
    ///////////////
    // Variables //
    ///////////////

    /// @dev HyperWallet implementation contract
    address public immutable HYPER_WALLET;

    /// @dev Next id to mint
    uint256 walletId;

    /// @dev token address => system address
    mapping(address => address) public systemAddress;

    /// @dev module address => enabled/disabled
    mapping(address => bool) public modules;

    ///////////////
    // Events //
    ///////////////

    /// @dev Emitted when a module is toggled
    event ToggleModule(address module, bool status);

    /// @dev Emitted when a system address is set
    event SetSystemAddress(address token, address systemAddress);

    /// @dev Emitted when a new wallet is deployed
    event WalletCreated(address user, uint256 walletId, address wallet);

    constructor(address owner_) Ownable(owner_) ERC721("HyperWallet", "HW") {
        HYPER_WALLET = address(new HyperWallet(address(this)));
    }

    /**
     * @notice Creates a new HyperWallet for a user
     * @dev Deploys a new proxy wallet, initializes it, and mints an NFT to the user
     * @param user The address that will own the new wallet
     * @return wallet The address of the newly created wallet
     */
    function createWallet(address user) external returns (address wallet) {
        // deploy a new account contract
        wallet = Clones.clone(HYPER_WALLET);
        HyperWallet(payable(wallet)).initialize(walletId);

        // mint an NFT to the user
        _mint(user, walletId);

        emit WalletCreated(user, walletId++, wallet);
    }

    ///////////////
    //  Setters  //
    ///////////////

    /**
     * @notice Toggle a module to enable/disable it for HyperWallet
     * @dev Only callable by owner. Enables or disables a module for all wallets
     * @param module The address of the module to toggle
     * @param status true to enable, false to disable
     */
    function toggleModule(address module, bool status) external onlyOwner {
        modules[module] = status;

        emit ToggleModule(module, status);
    }

    /**
     * @notice Set the system address for a token
     * @dev Only callable by owner. Maps a token contract to its corresponding system address
     * @param token The ERC20 token contract address
     * @param _systemAddress The system address that will handle this token's operations
     */
    function setSystemAddress(address token, address _systemAddress) external onlyOwner {
        systemAddress[token] = _systemAddress;

        emit SetSystemAddress(token, _systemAddress);
    }
}
