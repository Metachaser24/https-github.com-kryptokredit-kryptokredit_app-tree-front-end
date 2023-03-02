// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AdminOnly {
    address public admin;

    constructor() {
        admin = msg.sender;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only the admin can call this function");
        _;
    }

}