// SPDX-License-Identifier: MIT

pragma solidity ^0.8;
pragma experimental ABIEncoderV2;

import "./DydxFlashloanBase.sol";
import "./ICallee.sol";

contract TestDyDxSoloMargin is ICallee, DydxFlashloanBase {
  address private constant SOLO = 0x1E0447b19BB6EcFdAe1e4AE1694b0C3659614e4e;

  address public flashUser;

  event Log(string message, uint val);

  struct MyCustomData {
    address token;
    uint repayAmount;
  }

  function initiateFlashLoan(address _token, uint _amount) external {
    ISoloMargin solo = ISoloMargin(SOLO);


    uint marketId = _getMarketIdFromTokenAddress(SOLO, _token);

    uint repayAmount = _getRepaymentAmountInternal(_amount);
    IERC20(_token).approve(SOLO, repayAmount);

    Actions.ActionArgs[] memory operations = new Actions.ActionArgs[](3);

    operations[0] = _getWithdrawAction(marketId, _amount);
    operations[1] = _getCallAction(
      abi.encode(MyCustomData({token: _token, repayAmount: repayAmount}))
    );
    operations[2] = _getDepositAction(marketId, repayAmount);

    Account.Info[] memory accountInfos = new Account.Info[](1);
    accountInfos[0] = _getAccountInfo();

    solo.operate(accountInfos, operations);
  }

  function callFunction(
    address sender,
    Account.Info memory account,
    bytes memory data
  ) public override {
    require(msg.sender == SOLO, "!solo");
    require(sender == address(this), "!this contract");

    MyCustomData memory mcd = abi.decode(data, (MyCustomData));
    uint repayAmount = mcd.repayAmount;

    uint bal = IERC20(mcd.token).balanceOf(address(this));
    require(bal >= repayAmount, "bal < repay");

    flashUser = sender;
    emit Log("bal", bal);
    emit Log("repay", repayAmount);
    emit Log("bal - repay", bal - repayAmount);
  }
}