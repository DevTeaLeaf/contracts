// SPDX-License-Identifier: MIT

pragma solidity ^0.8;

import "../openzeppelin/IERC20.sol";
import "./Uniswap.sol";

interface IUniswapV2Callee {
    function uniswapV2Call(address sender,uint amount0,uint amount1,bytes calldata data) external;
}

contract UniswapFlashSwap is IUniswapV2Callee {
    // Uniswap V2 router
    // 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    // Uniswap V2 factory
    address private constant FACTORY = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;

    event Log(string message, uint val);
    function testFlashSwap(address _tokenBorrow, uint _amount) external {
        address pair = IUniswapV2Factory(FACTORY).getPair(_tokenBorrow, WETH);
        require(pair != address(0), "!pair");

        address token0 = IUniswapV2Pair(pair).token0();
        address token1 = IUniswapV2Pair(pair).token1();
        uint amount0Out = _tokenBorrow == token0 ? _amount : 0;
        uint amount1Out = _tokenBorrow == token1 ? _amount : 0;

        bytes memory data = abi.encode(_tokenBorrow, _amount);

        IUniswapV2Pair(pair).swap(amount0Out, amount1Out, address(this), data);
    }

   function uniswapV2Call(
        address _sender,
        uint _amount0,
        uint _amount1,
        bytes calldata _data
    ) external override {
        address token0 = IUniswapV2Pair(msg.sender).token0();
        address token1 = IUniswapV2Pair(msg.sender).token1();
        address pair = IUniswapV2Factory(FACTORY).getPair(token0, token1);
        require(msg.sender == pair, "!pair");
        require(_sender == address(this), "!sender");

        (address tokenBorrow, uint amount) = abi.decode(_data, (address, uint));

        uint fee = ((amount * 3) / 997) + 1;
        uint amountToRepay = amount + fee;

        emit Log("amount", amount);
        emit Log("amount0", _amount0);
        emit Log("amount1", _amount1);
        emit Log("fee", fee);
        emit Log("amount to repay", amountToRepay);

        IERC20(tokenBorrow).transfer(pair, amountToRepay);
    }
}