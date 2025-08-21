// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

interface IHyperWallet {
    function allowance(address module, address hyperWallet) external view returns (bool);

    function doAction(address destination, bytes memory action) external;

    function doActions(address destination, bytes[] memory actions) external;

    function FACTORY() external view returns (address);

    function HYPE_SYSTEM_ADDRESS() external view returns (address);

    function initialize(address owner) external;

    function lastActionBlock() external view returns (uint256);

    function modules(address module) external view returns (bool);

    function transferTokenToCoreSpot(address token, uint256 amount) external;

    function toggleAllowance(address module, address hyperWallet, bool status) external;

    function toggleModule(address module, bool status) external;

    function transferHypeToCoreSpot() external payable;

    function walletId() external view returns (uint256);

    function withdraw(address token, uint256 amount, address to) external;
}
