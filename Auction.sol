// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol";

contract Auction is Ownable {

    IERC20 public token;
    IERC1155 public nft;

    uint public fee = 1 ether; //fee for creating auction
    uint public aucNumber = 1;

    constructor(IERC20 _address) {
        token = _address;
    }

    struct Auction {
        address seller;
        address nftAddr;
        uint min;
        uint max;
        uint id;
        uint amount;
        uint time;
        uint bestBid;
        address bestBidAddr;
        bool finished;
        bool done;
    }

    mapping(uint => Auction) public auctions;
    mapping(uint => mapping(address => bool)) public isVoted; // nubmer of vote -> voter -> isVoted
    mapping(address => uint[]) public sellerAuctions;
    mapping(address => mapping(uint => uint)) public nalances; //who -> number of vote -> balance

    function createAuction(address _nftAddr, uint id, uint amount, uint min, uint max, uint time) external payable {
        require(msg.sender != address(0));
        require(msg.value >= fee,"incorrect pay");

        if(max == 0) {
            max = 9999999999 ether;
        }
        require(min > 0 && max > min && time > 0,"incorrect settings");
        nft = IERC1155(_nftAddr);

        nft.safeTransferFrom(msg.sender,address(this),id,amount,"");
        auctions[aucNumber] = Auction(msg.sender,_nftAddr,min,max,id, amount, block.timestamp+time, 0 , address(0), false, false);

        sellerAuctions[msg.sender].push(aucNumber);
        aucNumber++;
    }

    function vote(uint number,uint price) external payable {

        if(block.timestamp > auctions[number].time && !auctions[number].finished) {
            finishAuction(number);
        }

        require(msg.value >= price && msg.value >= auctions[number].min && msg.value >= auctions[number].bestBid,"incorrect pay");
        require(block.timestamp < auctions[number].time);
        require(!auctions[number].finished, "voting is finished");

        if(price >= auctions[number].max) {
            finishAuctionMax(number,msg.value);
            auctions[number].bestBid = price;
            auctions[number].bestBidAddr = msg.sender;
        } else {
            auctions[number].bestBid = price;
            auctions[number].bestBidAddr = msg.sender;
        }

        balances[msg.sender][number] += price;

    }

    function finishAuction(uint number) internal {
        auctions[number].finished = true;
        nft = IERC1155(auctions[number].nftAddr);
        nft.safeTransferFrom(address(this),auctions[number].bestBidAddr,auctions[number].id,auctions[number].amount,"");
        payable(auctions[number].seller).transfer(auctions[number].bestBid);
    }

    function finishAuctionMax(uint number, uint price) internal {
        auctions[number].finished = true;
        nft = IERC1155(auctions[number].nftAddr);
        nft.safeTransferFrom(address(this), msg.sender, auctions[number].id, auctions[number].amount, "");
        payable(auctions[number].seller).transfer(price);
    }
 
    function backNFT (uint number) external {
        if(block.timestamp > auctions[number].time && !auctions[number].finished) {
            auctions[number].finished = true;
        }
        require(auctions[number].seller == msg.sender,"not an owner");
        require(!auctions[number].done ,"already claimed");
        require(block.timestamp > auctions[number].time,"Voting is not finished");
        if(auctions[number].bestBid > 0) {
            auctions[number].done = true;
            finishAuction(number);
        } else {
            auctions[number].done = true;
            nft.safeTransferFrom(address(this),msg.sender,auctions[number].id,auctions[number].amount,"");
        }
    }

    function changeFee(uint _newFee) external onlyOwner {
        require(_newFee <= 1 ether,"incorrect fee");
        fee = _newFee;
    }
    
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external pure returns (bytes4) {
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }

}