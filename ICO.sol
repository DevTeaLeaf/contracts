// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./Ownable.sol";

interface IERC20 {
    function transfer(address to,uint amount) external returns (bool);
    function transferFrom(address from, address to, uint amount) external returns (bool);
    function balanceOf(address account) external view returns (uint);
    function mint(address _to, uint _amount) external;
}

interface IUniswapV3Router {
    function getAmountOut(address tokenIn,address tokenOut,uint128 amountIn,uint24 fee,uint32 secondsAgo) external view returns (uint amountOut);
}


contract MetaluxICO is Ownable {

    mapping(address => bool) public allowedTokens;

    bool public ICOstarted;
    bool public setted;

    uint public stageTwo;
    uint public stageThree;
    uint public ICOEnd;
    uint public currentStage = 1;

    uint public minPurchase = 10000000; //10$
    uint public minPurchaseBUSD = 10 ether; //10 busd === 10 ** 18

    uint public stageOnePrice = 100000; //0,1$
    uint public stageTwoPrice = 150000; //0,15$
    uint public stageThreePrice = 200000; //0,2$

    uint public stageOnePriceDiscount10k = 80000; //0,08$
    uint public stageOnePriceDiscount50k = 60000; //0,06$
    uint public stageOnePriceDiscount100k = 50000; //0,05$

    uint public stageTwoPriceDiscount10k = 110000; //0,11$
    uint public stageTwoPriceDiscount50k = 90000; //0,09$
    uint public stageTwoPriceDiscount100k = 80000; //0,08$


    uint public stageThreePriceDiscount10k = 150000; //0,15$
    uint public stageThreePriceDiscount50k = 120000; //0,12$
    uint public stageThreePriceDiscount100k = 100000; //0,1$

    uint public stageOneAmountToSell = 9_265_000 ether;
    uint public stageTwoAmountToSell = 17_440_000 ether;
    uint public stageThreeAmountToSell = 27_795_000 ether;

    address public luxToken;
    address public WMATICToken = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
    address public usdtToken = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F;
    address public usdcToken = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
    address public DAIToken = 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063;
    address public busdToken = 0x9C9e5fD8bbc25984B178FdCE6117Defa39d2db39;
    address rd;

    IUniswapV3Router public oracle; 

    address public toOwner = 0xE6E7A02bb8457D4F2C07560092f255f19986E38A;
    address public toSecondOwner = 0x9cAa904e2eF96945f522c907d2dB288e41cba68F;

    mapping(address => address) public refferal;

    constructor(address _router,address _rd, address[] memory _allowedTokens) {
        rd = _rd;
        oracle = IUniswapV3Router(_router);
        for(uint i; i<_allowedTokens.length;i++) {
            allowedTokens[_allowedTokens[i]] = true;
        }
    } 

    function _checkStage(uint amountToBuy) private returns(uint _rest) {
        require(ICOstarted,"ICO has not started");
        if(block.timestamp > stageTwo && currentStage != 2) {
            currentStage = 2;
            stageTwoAmountToSell += stageOneAmountToSell;
            stageOneAmountToSell = 0;
        }else if(block.timestamp > stageThree && currentStage != 3) {
            currentStage = 3;
            stageThreeAmountToSell += stageTwoAmountToSell;
            stageTwoAmountToSell = 0;
        }

        uint _amountToBuy = amountToBuy * 1 ether;

        if(currentStage == 1) {
            if(_amountToBuy > stageOneAmountToSell) {
                _rest = (_amountToBuy - stageOneAmountToSell) / 1 ether;
                require(stageTwoAmountToSell >= _rest * 1 ether,"Incorrect amount");
                stageTwoAmountToSell -= _rest * 1 ether;
                stageOneAmountToSell = 0;
                currentStage = 2;
            } else {
                stageOneAmountToSell -= _amountToBuy;
            }
        } else if(currentStage == 2) {
            if (_amountToBuy > stageTwoAmountToSell) {
                _rest = (_amountToBuy - stageTwoAmountToSell)/1 ether;
                require(stageThreeAmountToSell >= _rest * 1 ether, "Incorrect amount");
                stageThreeAmountToSell -= _rest * 1 ether;
                stageTwoAmountToSell = 0;
                currentStage = 3;
            } else {
                stageTwoAmountToSell -= _amountToBuy;
            }
        } else {
            require(stageThreeAmountToSell >= _amountToBuy, "Incorrect amount");
            stageThreeAmountToSell -= _amountToBuy;
            if(stageThreeAmountToSell == 0) {
                ICOEnd = block.timestamp;
            }
        }
    }

    // amountToBuy is 1 = 1 token. No decimals
    function invest(uint amountToBuy,address payToken,address ref) external payable {
        require(allowedTokens[payToken],"Incorrect payment token");
        if(refferal[msg.sender] == address(0) && ref != address(0)) {
            refferal[msg.sender] = ref;
        }else {
            refferal[msg.sender] = rd;
        }

        uint _rest = _checkStage(amountToBuy);
        if(msg.value == 0) {
            if(payToken == usdtToken || payToken == usdcToken || payToken == DAIToken || payToken == busdToken){
                uint amountToPay;
                if(_rest > 0) {
                    uint _firstPay = checkPriceStable(amountToBuy - _rest, payToken);
                    uint _secondPay = checkPriceStable(_rest, payToken);
                    amountToPay = _firstPay + _secondPay;
                } else {
                    amountToPay = checkPriceStable(amountToBuy, payToken);
                }
                if(payToken == busdToken) {
                    require(amountToPay >= minPurchaseBUSD, "Minimum purchase is must be equal 10$");
                } else {
                    require(amountToPay >= minPurchase, "Minimum purchase is must be equal 10$");
                }
                IERC20(payToken).transferFrom(msg.sender, address(this), amountToPay);
                IERC20(luxToken).mint(msg.sender, amountToBuy * 1 ether);
                sendReward(amountToPay, payToken, false);
            } else {
                uint amountToPay;
                uint toPayStable;
                if(_rest > 0) {
                    (uint _toPayToken1, uint _toPayStable1) = checkPrice(amountToBuy - _rest, payToken);
                    (uint _toPayToken2, uint _toPayStable2) = checkPrice(_rest, payToken);
                    amountToPay = _toPayToken1 + _toPayToken2;
                    toPayStable = _toPayStable1 + _toPayStable2;
                } else {
                    (amountToPay,  toPayStable) = checkPrice(amountToBuy, payToken);
                }
                require(toPayStable >= minPurchase, "Minimum purchase is must be equal 10$");
                IERC20(payToken).transferFrom(msg.sender, address(this), amountToPay);
                IERC20(luxToken).mint(msg.sender, amountToBuy * 1 ether);
                sendReward(amountToPay, payToken, false);
            } 
        } else {
            uint amountToPay;
            uint toPayStable;
            if(_rest > 0) {
                (uint _toPayToken1,uint _toPayStable1) = checkPrice(amountToBuy - _rest,WMATICToken);
                (uint _toPayToken2,uint _toPayStable2) = checkPrice(_rest,WMATICToken);
                amountToPay = _toPayToken1 + _toPayToken2;
                toPayStable = _toPayStable1 + _toPayStable2;
            }else {
                (amountToPay,toPayStable) = checkPrice(amountToBuy,WMATICToken);
            }
            require(toPayStable>= minPurchase,"Minimum purchase is must be equal 10$");
            require(msg.value >= amountToPay,"Incorrect amount of MATIC");
            IERC20(luxToken).mint(msg.sender,amountToBuy * 1 ether);
            sendReward(amountToPay,payToken,true);
        }
    }

    function sendReward(uint amountToPay,address payToken,bool native) private {
        address firstLVL = refferal[msg.sender];
        address secondLVL = refferal[firstLVL] == address(0) ? rd : refferal[firstLVL];
        
        uint ten = amountToPay / 10;
        uint three = amountToPay / 33;
        if(native) {
            payable(firstLVL).transfer(ten);
            payable(secondLVL).transfer(three);
        }else {
            IERC20(payToken).transfer(firstLVL, ten);
            IERC20(payToken).transfer(secondLVL, three);
        }
    }

    function checkPriceStable(uint amountToBuy,address payToken) public view returns(uint) {
        uint _priceStageOne;
        uint _priceStageTwo;
        uint _priceStageThree;
        uint amountToPay;

        if(amountToBuy >= 100000) {
            _priceStageOne = stageOnePriceDiscount100k;
            _priceStageTwo = stageTwoPriceDiscount100k;
            _priceStageThree =  stageThreePriceDiscount100k;
        } else if (amountToBuy >= 50000) {
            _priceStageOne = stageOnePriceDiscount50k;
            _priceStageTwo = stageTwoPriceDiscount50k;
            _priceStageThree =  stageThreePriceDiscount50k;
        } else if (amountToBuy >= 10000) {
            _priceStageOne = stageOnePriceDiscount10k;
            _priceStageTwo = stageTwoPriceDiscount10k;
            _priceStageThree =  stageThreePriceDiscount10k;
        } else {
            _priceStageOne = stageOnePrice;
            _priceStageTwo = stageTwoPrice;
            _priceStageThree =  stageThreePrice;
        }

        if (payToken == busdToken) {
            _priceStageOne = _priceStageOne * 10 ** 12;
            _priceStageTwo = _priceStageTwo * 10 ** 12;
            _priceStageThree = _priceStageThree * 10 ** 12;
        }

        if(block.timestamp < stageTwo) {
            amountToPay = amountToBuy * _priceStageOne;
            return amountToPay;
        } else if (block.timestamp < stageThree){
            amountToPay = amountToBuy * _priceStageTwo;
            return amountToPay;
        } else {
            amountToPay = amountToBuy * _priceStageThree;
            return amountToPay;
        }
    }

    function checkPrice(uint amountToBuy, address payToken) public view returns(uint, uint) {
        uint _priceStageOne;
        uint _priceStageTwo;
        uint _priceStageThree;

        if(amountToBuy >= 100000) {
            _priceStageOne = stageOnePriceDiscount100k;
            _priceStageTwo = stageTwoPriceDiscount100k;
            _priceStageThree =  stageThreePriceDiscount100k;
        } else if (amountToBuy >= 50000) {
            _priceStageOne = stageOnePriceDiscount50k;
            _priceStageTwo = stageTwoPriceDiscount50k;
            _priceStageThree =  stageThreePriceDiscount50k;
        } else if (amountToBuy >= 10000) {
            _priceStageOne = stageOnePriceDiscount10k;
            _priceStageTwo = stageTwoPriceDiscount10k;
            _priceStageThree =  stageThreePriceDiscount10k;
        } else {
            _priceStageOne = stageOnePrice;
            _priceStageTwo = stageTwoPrice;
            _priceStageThree =  stageThreePrice;
        }

        if(block.timestamp < stageTwo) {
            //stage1
            uint128 amountToPay = uint128(amountToBuy * _priceStageOne);
            uint responce = oracle.getAmountOut(usdtToken, payToken, amountToPay, 500, 10);
            return (responce, amountToPay);
        } else if (block.timestamp < stageThree){
            //stage2
            uint128 amountToPay = uint128(amountToBuy * _priceStageTwo);
            uint responce = oracle.getAmountOut(usdtToken, payToken, amountToPay, 500, 10);
            return (responce, amountToPay);
        } else {
            //stage3
            uint128 amountToPay = uint128(amountToBuy * _priceStageThree);
            uint responce = oracle.getAmountOut(usdtToken, payToken, amountToPay, 500, 10);
            return (responce, amountToPay);
        }
    }

     //=================================ADMIN FUNCTIONS=========================================

    function withdrawToken(address token) external onlyOwner {
        uint balanceOwner = IERC20(token).balanceOf(address(this)) * 6700 / 10000;
        uint balanceSecondOwner = IERC20(token).balanceOf(address(this)) - balanceOwner;

        IERC20(token).transfer(toSecondOwner,balanceSecondOwner);
        IERC20(token).transfer(toOwner,balanceOwner);
    }

    function withdrawMatic() external onlyOwner {
        uint balanceOwner = address(this).balance * 6700 / 10000;
        uint balanceSecondOwner = address(this).balance - balanceOwner;
        payable(toSecondOwner).transfer(balanceSecondOwner);
        payable(toOwner).transfer(balanceOwner);
    } 
    function setToken(address _luxToken) external onlyOwner {
        require(!setted,"Token already setted");
        setted = true;
        luxToken = _luxToken;
    }

    function startICO() external onlyOwner {
        require(!ICOstarted,"ICO already started");
        ICOstarted = true;
        stageTwo = block.timestamp + 30 days; //setting END of stage
        stageThree = stageTwo + 45 days;
        ICOEnd = stageThree + 105 days;
    }
}
