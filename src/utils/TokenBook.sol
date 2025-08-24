// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "openzeppelin/access/Ownable2Step.sol";

contract TokenBook is Ownable2Step {
    struct TokenInfo {
        address systemAddress;
        uint64 tokenIdCoreSpot;
    }

    mapping(address => TokenInfo) public tokens;

    error TokenNotAdded(address token);

    event AddToken(TokenInfo tokenInfo);

    constructor(address owner_) Ownable(owner_) {}

    function addTokenInfo(address token, TokenInfo calldata info) external onlyOwner {
        tokens[token] = info;

        emit AddToken(info);
    }

    function getTokenInfoByEvmAddress(address token) external view returns (TokenInfo memory) {
        TokenInfo memory tokenInfo = tokens[token];
        if (tokenInfo.systemAddress == address(0)) revert TokenNotAdded(token);
        return tokenInfo;
    }
}
