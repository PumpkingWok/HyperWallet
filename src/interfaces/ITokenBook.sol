// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

interface ITokenBook {
    struct TokenInfo {
        address systemAddress;
        uint64 tokenIdCoreSpot;
    }

    function addTokenInfo(TokenInfo memory info) external;
    function getTokenInfoByEvmAddress(address evmToken) external view returns (TokenInfo memory);
    function tokens(address evmToken) external view returns (TokenInfo memory);
}
