// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./Uniswap.sol";
import "../openzeppelin/IERC20.sol";


contract TestUniswap {

    address private constant UNISWAP_V2_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address private constant FACTORY = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;

    event Log(string message,uint val);

    function swap(
        address _tokenIn, address _tokenOut,uint _amountIn,uint _amountOutMin,address _to
    )external {
        IERC20(_tokenIn).transferFrom(msg.sender,address(this),_amountIn);
        IERC20(_tokenIn).approve(UNISWAP_V2_ROUTER,_amountIn);

        address[] memory path;
        path = new address[](3);
        path[0] = _tokenIn;
        path[1] = WETH;
        path[2] =_tokenOut;

        IUniswapV2Router(UNISWAP_V2_ROUTER).swapExactTokensForTokens(_amountIn, _amountOutMin, path, _to, block.timestamp);
    }

   function addLiquidity(address _tokenA,address _tokenB,uint _amountA,uint _amountB) external {

    IERC20(_tokenA).transferFrom(msg.sender,address(this),_amountA);
    IERC20(_tokenB).transferFrom(msg.sender,address(this),_amountB);

    IERC20(_tokenA).approve(UNISWAP_V2_ROUTER,_amountA);
    IERC20(_tokenB).approve(UNISWAP_V2_ROUTER,_amountB);


    (uint amountA,uint amountB,uint liquidity)=IUniswapV2Router(UNISWAP_V2_ROUTER).addLiquidity(_tokenA, _tokenB, _amountA, _amountB, 1,1,address(this),block.timestamp);
   
    emit Log("amountA",amountA);
    emit Log("amountB",amountB);
    emit Log("liquidity",liquidity);
   }

    function removeLiquidity(address _tokenA,address _tokenB) external {
        address pair = IUniswapV2Factory(FACTORY).getPair(_tokenA, _tokenB);

        uint liquidity = IERC20(pair).balanceOf(address(this));

        IERC20(pair).approve(UNISWAP_V2_ROUTER,liquidity);

        (uint amountA,uint amountB)=IUniswapV2Router(UNISWAP_V2_ROUTER).removeLiquidity(_tokenA, _tokenB, liquidity, 1,1,address(this),block.timestamp);
    }
}