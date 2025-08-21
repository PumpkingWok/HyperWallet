// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract MockCoreUserExists {
    struct CoreUserExists {
        bool exists;
    }

    mapping(address => CoreUserExists) public coreUserExists;

    function setCoreUserExists(address user, bool exists) external {
        coreUserExists[user] = CoreUserExists(exists);
    }

    fallback() external {
        (address user) = abi.decode(msg.data, (address));
        bytes memory encoded = abi.encode(coreUserExists[user]);
        assembly {
            return(add(encoded, 0x20), mload(encoded))
        }
    }
}
