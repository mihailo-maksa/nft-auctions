// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./MockToken.sol";

contract CrowdFund {
  event Launch(uint campaignId, address indexed creator, uint goal, uint32 startAt, uint32 endAt);
  event Cancel(uint campaignId);
  event Pledge(uint indexed campaignId, address indexed funder, uint amount);
  event Unpledge(uint indexed campaignId, address indexed funder, uint amount);
  event Claim(uint campaignId);
  event Refund(uint indexed campaignId, address indexed funder, uint amount);

  struct Campaign {
    address creator;
    uint goal;
    uint pledged;
    uint32 startAt;
    uint32 endAt;
    bool claimed;
  }

  uint public count;
  mapping(uint => Campaign) public campaigns;
  mapping(uint => mapping(address => uint)) public pledgedAmount;
  

  IERC20 public immutable token;

  constructor(address _token) {
    token = IERC20(_token);
  }

  function launch(uint _goal, uint32 _startAt, uint32 _endAt) external {
    require(_startAt >= block.timestamp, "CrowdFund: campaign must start in the future");
    require(_endAt > _startAt, "CrowdFund: end time is before start time");
    require(_endAt <= _startAt + uint32(90 days), "CrowdFund: max campaign duration exceeded");

    count += 1;
    campaigns[count] = Campaign({
      creator: msg.sender,
      goal: _goal,
      pledged: 0,
      startAt: _startAt,
      endAt: _endAt,
      claimed: false
    });

    emit Launch(count, msg.sender, _goal, _startAt, _endAt);
  }

  function cancel(uint _id) external {
    Campaign memory campaign = campaigns[_id];

    require(msg.sender == campaign.creator, "CrowdFund: only creator can cancel the campaign");
    require(campaign.startAt > block.timestamp, "CrowdFund: campaign already started");
    
    delete campaign;
    emit Cancel(_id);
  }

  function pledge(uint _id, uint _amount) external {
    Campaign storage campaign = campaigns[_id];

    require(campaign.startAt <= block.timestamp, "CrowdFund: campaign has not started yet");
    require(campaign.endAt >= block.timestamp, "CrowdFund: campaign already ended");

    campaign.pledged += _amount;
    pledgedAmount[_id][msg.sender] += _amount;
    token.transferFrom(msg.sender, address(this), _amount);

    emit Pledge(_id, msg.sender, _amount);
  }

  function unpledge(uint _id, uint _amount) external {
    Campaign storage campaign = campaigns[_id];

    require(campaign.endAt >= block.timestamp, "CrowdFund: campaign already ended");
    require(pledgedAmount[_id][msg.sender] > 0, "CrowdFund: user has not pledged any tokens yet to this campaign");

    campaign.pledged -= _amount;
    pledgedAmount[_id][msg.sender] -= _amount;
    token.transfer(msg.sender, _amount);

    emit Unpledge(_id, msg.sender, _amount);
  }

  function claim(uint _id) external {
    Campaign storage campaign = campaigns[_id];

    require(msg.sender == campaign.creator, "CrowdFund: only campaign creator can call this method");
    require(block.timestamp > campaign.endAt, "CrowdFund: campaign is still active");
    require(!campaign.claimed, "CrowdFund: funds already claimed");
    require(campaign.pledged >= campaign.goal, "CrowdFund: campaign goal not reached");

    campaign.claimed = true;
    token.transfer(msg.sender, campaign.pledged);

    emit Claim(_id);
  }

  function refund(uint _id) external {
    Campaign storage campaign = campaigns[_id];

    require(pledgedAmount[_id][msg.sender] > 0, "CrowdFund: user has not pledged any tokens to this campaign");
    require(block.timestamp > campaign.endAt, "CrowdFund: campaign is still active");
    require(campaign.pledged < campaign.goal, "CrowdFund: campaign goal has been reached - no refund available");

    uint amount = pledgedAmount[_id][msg.sender];
    pledgedAmount[_id][msg.sender] = 0;
    token.transfer(msg.sender, amount);

    emit Refund(_id, msg.sender, amount);
  }
}
