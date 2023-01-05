// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC20.sol";

contract TestToken is ERC20 {
  constructor() ERC20("TestToken", "TTK", 1000) {}
}