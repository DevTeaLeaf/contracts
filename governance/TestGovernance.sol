// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract TestGovernance {
    string public message;
    mapping(address => uint) balances;
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function transferOwnership (address _to) external {
        require(msg.sender == owner,"You are not owner!");
        owner = _to;
    }

    function pay(string calldata _message) external payable {
        require(msg.sender == owner,"You are not owner!");
        message = _message;
        balances[msg.sender] = msg.value;
    }
}