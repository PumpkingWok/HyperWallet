// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

interface IHyperWalletFactory {
    function modules(address module) external view returns (bool);

    function ownerOf(uint256 walletId) external view returns (address);

    function systemAddress(address token) external view returns (address);
}
