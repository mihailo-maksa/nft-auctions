// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./MockNFT.sol";

// Decreasing price over time, ends when buyer decides price is low enough
contract DutchAuction {
  uint private constant DURATION = 7 days;

  address public immutable seller;
  IERC721 public immutable nft;
  uint public immutable nftId;
  uint public immutable startAt;
  uint public immutable expiresAt;
  uint public immutable startingPrice;
  uint public immutable discountRate;

  constructor(address _nft, uint _nftId, uint _startingPrice, uint _discountRate) {
    seller = msg.sender;

    require(_startingPrice >= _discountRate * DURATION, "DutchAuction: starting price is set too low");
    startingPrice = _startingPrice;
    discountRate = _discountRate;

    startAt = block.timestamp;
    expiresAt = block.timestamp + DURATION;

    nft = IERC721(_nft);
    nftId = _nftId;
  }

  function getPrice() public view returns (uint) {
    uint timeElapsed = block.timestamp - startAt;
    uint discount = discountRate * timeElapsed;
    return startingPrice - discount;
  }

  function buyNFT() external payable {
    require(block.timestamp < expiresAt, "DutchAuction: auction expired");

    uint price = getPrice();

    require(msg.value >= price, "DutchAuction: not enough ether sent");
    nft.transferFrom(seller, msg.sender, nftId);

    uint refund = msg.value - price;
    if (refund > 0) {
      (bool sent, ) = msg.sender.call{value: refund}("");
      require(sent, "DutchAuction: ether refund failed");
    }

    selfdestruct(payable(seller));
  }
}