// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

interface ICoreWriter {
    function sendRawAction(bytes calldata data) external;
}
