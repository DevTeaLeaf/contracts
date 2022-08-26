// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Factory {

    function deploy(address _owner,uint _foo,bytes32 _salt) public payable returns(address) {
        // This syntax is a newer way to invoke create2 without assembly, you just need to pass salt
        // https://docs.soliditylang.org/en/latest/control-structures.html#salted-contract-creations-create2
        return address(new TestContract{salt:_salt}(_owner,_foo));
    }
}

contract TestContract {
    address public owner;
    uint public foo;

    constructor(address _owner,uint _foo) payable {
        owner = _owner;
        foo = _foo;
    }

    function getBalance() public view returns(uint) {
        return address(this).balance;
    }
}
