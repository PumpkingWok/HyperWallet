// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

interface IL1Read {
    struct CoreUserExists {
        bool exists;
    }

    struct Position {
        int64 szi;
        uint64 entryNtl;
        int64 isolatedRawUsd;
        uint32 leverage;
        bool isIsolated;
    }

    struct SpotBalance {
        uint64 total;
        uint64 hold;
        uint64 entryNtl;
    }

    struct Withdrawable {
        uint64 withdrawable;
    }

    function spotBalance(address user, uint64 token) external view returns (SpotBalance memory);

    function withdrawable(address user) external view returns (Withdrawable memory);

    function markPx(uint32 index) external view returns (uint64);

    function position(address user, uint16 index) external view returns (Position memory);

    function spotPx(uint32 index) external view returns (uint64);

    function coreUserExists(address user) external view returns (CoreUserExists memory);
}
