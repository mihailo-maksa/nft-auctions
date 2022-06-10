// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./MockNFT.sol";

contract EnglishAuction {
  event Start(uint32 timestamp);
  event Bid(address indexed bidder, uint value);
  event Withdrawal(address indexed bidder, uint value);
  event End(address highestBidder, uint highestBid);

  uint private constant DURATION = 3 minutes;

  IERC721 public immutable nft;
  uint public immutable nftId;

  address public immutable seller;
  address public highestBidder;
  uint public highestBid;

  mapping(address => uint) public bids;

  uint32 public endAt;
  bool public started;
  bool public ended;

  constructor(address _nft, uint _nftId, uint _startingPrice) {
    nft = IERC721(_nft);
    nftId = _nftId;
    seller = msg.sender;
    highestBid = _startingPrice;
  }

  modifier onlySeller() {
    require(msg.sender == seller, "onlySeller: only seller can call this method");
    _;
  }

  modifier notExpired() {
    require(block.timestamp < endAt, "notExpired: auction expired");
    _;
  }

  modifier hasExpired() {
    require(block.timestamp >= endAt, "notExpired: auction not expired yet");
    _;
  }

  modifier isActive() {
    require(started && !ended, "isActive: auction is not active at the moment");
    _;
  }

  modifier isNotActive() {
    require(ended, "isNotActive: aucton is still active");
    _;
  }

  function getContractBalance() external view returns (uint) {
    return address(this).balance;
  }

  function startAuction() external onlySeller {
    require(!started, "EnglishAuction: auction already started");
    started = true;
    endAt = uint32(block.timestamp + DURATION);
    nft.transferFrom(seller, address(this), nftId);
    emit Start(uint32(block.timestamp));
  }

  function placeBid() external payable notExpired isActive {
    require(msg.value > highestBid, "EnglishAuction: please set a higher bid");

    if (highestBidder != address(0)) {
      bids[highestBidder] += highestBid;
    }

    highestBid = msg.value;
    highestBidder = msg.sender; 

    emit Bid(msg.sender, msg.value);
  }

  function endAuction() external isActive hasExpired {
    ended = true;

    if (highestBidder != address(0)) {
      nft.transferFrom(address(this), highestBidder, nftId);
      (bool sent, ) = msg.sender.call{value: highestBid}("");
      require(sent, "EnglishAuction: ether transfer to seller failed");
    } else {
      nft.transferFrom(address(this), seller, nftId);
    }

    emit End(highestBidder, highestBid);
  }

  function withdrawEther() external  {
    require(msg.sender != highestBidder, "EnglishAuction: highest bidder can't withdraw ETH");
    require(bids[msg.sender] > 0, "EnglishAuction: user has not place any bids");

    uint bid = bids[msg.sender];
    bids[msg.sender] = 0;
    
    (bool sent, ) = msg.sender.call{value: bid}("");
    require(sent, "EnglishAuction: ether transfer to bidder failed"); 
  
    emit Withdrawal(msg.sender, bid);
  }
}
