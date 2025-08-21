// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {IHyperWalletFactory} from "./interfaces/IHyperWalletFactory.sol";
import {Initializable} from "openzeppelin-upgradeable/proxy/utils/Initializable.sol";
import {SafeTransferLib} from "solady/utils/SafeTransferLib.sol";

/// @notice HyperWallet
/// @author HyperWallet Labs
contract HyperWallet is Initializable {
    ///////////////
    // Variables //
    ///////////////

    /// @dev HYPE token system address (send hype to it to receive on core)
    address public constant HYPE_SYSTEM_ADDRESS = 0x2222222222222222222222222222222222222222;

    /// @dev HyperWallet factory contract
    IHyperWalletFactory public immutable FACTORY;

    /// @dev NFT id
    uint256 public walletId;

    /// @dev store last action block, it allows at most one action per block
    uint256 public lastActionBlock;

    /// @dev modules enabled
    mapping(address => bool) public modules;

    /// @dev allowed addresses for each module
    mapping(address => mapping(address => bool)) public allowance; // module -> address -> allowed

    ///////////////
    // Errors //
    ///////////////

    /// @dev Thrown if a low level call fails
    error ActionFailed();

    /// @dev Thrown if in the current block another action has executed
    error BlockAlreadyUsed();

    /// @dev Thrown if the module is not active in the factory
    error ModuleNotActive();

    /// @dev Thrown if the module is not enabled for this wallet
    error ModuleNotEnabled();

    /// @dev Thrown if caller is not the NFT holder of this wallet
    error NotNftHolder();

    /// @dev Thrown if caller is not the owner
    error OnlyOwner();

    /// @dev Thrown when the token is not supported by the factory
    error TokenNotSupported();

    ///////////////
    // Events //
    ///////////////

    /// @dev Emitted when an action is executed
    event ActionExecuted(address destination, bytes action);

    /// @dev Emitted when a module is enabled/disabled
    event ToggleModule(address module, bool status);

    /// @dev Emitted when an address is allowed/disallowed to interact with a module
    event ToggleAllowance(address module, address allowed, bool status);

    /// @dev Emitted when tranfers hype to core
    event TransferHypeToCoreSpot(uint256 amount);

    /// @dev Emitted when tranfers funds from evm to core
    event TransferTokenToCoreSpot(address token, uint256 amount);

    /// @dev Emitted when withdraws funds from the wallet
    event Withdraw(address token, uint256 amount, address to);

    constructor(address factory_) {
        FACTORY = IHyperWalletFactory(factory_);
    }

    /**
     * @dev Initialize function
     * @param walletId_ HyperWallet NFT id
     */
    function initialize(uint256 walletId_) external initializer {
        walletId = walletId_;
    }

    /**
     * @dev Transfer HYPE (native token) to core, anyone can call it
     */
    function transferHypeToCoreSpot() external payable {
        _transferHypeToCoreSpot();
    }

    /**
     * @dev Transfer token from evm to core spot, anyone can call it
     * @param token Token to transfer
     * @param amount Amount to transfer (decimals = 8)
     */
    function transferTokenToCoreSpot(address token, uint256 amount) external {
        // transfer token to Core, this contract address will receive it as spot balance
        // retrieve token system address from registry/factory
        address systemAddress = FACTORY.systemAddress(token);
        if (systemAddress == address(0)) {
            revert TokenNotSupported();
        }
        SafeTransferLib.safeTransferFrom(token, msg.sender, address(this), amount);
        SafeTransferLib.safeTransfer(token, systemAddress, amount);

        emit TransferTokenToCoreSpot(token, amount);
    }

    /**
     * @dev Withdrawn token from the wallet
     * @param token Token to withdraw
     * @param amount Amount to withdraw (token decimals)
     * @param to Address to receive the token
     */
    function withdraw(address token, uint256 amount, address to) external onlyNftHolder {
        SafeTransferLib.safeTransfer(token, to, amount);
        emit Withdraw(token, amount, to);
    }

    /**
     * @dev Core entry point for every module (one action)
     * @param destination The destination address to call the action
     * @param action The encoded action data to call
     * @notice This function can only be called by enabled modules and only once per block
     */
    function doAction(address destination, bytes memory action) external onlyModuleEnabled oneActionPerBlock {
        _doAction(destination, action);
    }

    /**
     * @dev Core entry point for every module (multi actions)
     * @param destination The destination address to call the actions
     * @param actions Array of encoded action data to call sequentially
     * @notice This function can only be called by enabled modules and only once per block
     */
    function doActions(address destination, bytes[] memory actions) external onlyModuleEnabled oneActionPerBlock {
        uint256 length = actions.length;
        for (uint256 i = 0; i < length;) {
            _doAction(destination, actions[i]);
            unchecked {
                ++i;
            }
        }
    }

    ///////////////
    //  Setters  //
    ///////////////

    /**
     * @dev Enable/disable an existing module
     * @param module module to enable/disable
     * @param status true=enable, false=disable
     */
    function toggleModule(address module, bool status) external onlyNftHolder {
        // check if it is a valid module
        if (!FACTORY.modules(module)) revert ModuleNotActive();
        modules[module] = status;

        emit ToggleModule(module, status);
    }

    /**
     * @dev Approve/disapprove an address to interact with a module on behalf of the user
     * @param module module to allow
     * @param allowed address to allow
     * @param status approve/disapprove an address
     */
    function toggleAllowance(address module, address allowed, bool status) external onlyNftHolder {
        allowance[module][allowed] = status;

        emit ToggleAllowance(module, allowed, status);
    }

    /**
     * @dev Internal function to trigger the raw call()
     * @param destination destination address
     * @param action action to call
     */
    function _doAction(address destination, bytes memory action) internal {
        (bool result,) = destination.call(action);
        if (!result) revert ActionFailed();

        emit ActionExecuted(destination, action);
    }

    /**
     * @dev Internal function to transfer HYPE to core
     */
    function _transferHypeToCoreSpot() internal {
        if (msg.value != 0) {
            payable(HYPE_SYSTEM_ADDRESS).transfer(msg.value);
            emit TransferHypeToCoreSpot(msg.value);
        }
    }

    /**
     * @dev Internal function to check if the module is enabled by the wallet
     */
    function _onlyModuleEnabled() internal view {
        if (!modules[msg.sender]) revert ModuleNotEnabled();
    }

    /**
     * @dev Internal function to check if there was another action in the same block
     */
    function _oneActionPerBlock() internal {
        if (block.number == lastActionBlock) revert BlockAlreadyUsed();
        lastActionBlock = block.number;
    }

    /**
     * @dev Internal function to check the NFT ownership
     */
    function _onlyNftHolder() internal view {
        if (FACTORY.ownerOf(walletId) != msg.sender) revert NotNftHolder();
    }

    modifier onlyModuleEnabled() {
        _onlyModuleEnabled();
        _;
    }

    modifier oneActionPerBlock() {
        _oneActionPerBlock();
        _;
    }

    modifier onlyNftHolder() {
        _onlyNftHolder();
        _;
    }

    /**
     * @dev receive function, it supports to transfer HYPE to this contract
     */
    receive() external payable {
        _transferHypeToCoreSpot();
    }
}
