// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract MockSpotBalance {
    struct SpotBalance {
        uint64 total;
        uint64 hold;
        uint64 entryNtl;
    }

    mapping(address => mapping(uint64 => SpotBalance)) public spotBalances;

    function setSpotBalance(address user, uint64 token, uint64 total, uint64 hold, uint64 entryNtl) external {
        spotBalances[user][token] = SpotBalance(total, hold, entryNtl);
    }

    fallback() external {
        (address user, uint64 token) = abi.decode(msg.data, (address, uint64));
        bytes memory encoded = abi.encode(spotBalances[user][token]);
        assembly {
            return(add(encoded, 0x20), mload(encoded))
        }
    }
}
