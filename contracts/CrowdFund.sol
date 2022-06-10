// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./MockToken.sol";

contract CrowdFund {
  IERC20 public immutable token;

  constructor(address _token) {
    token = IERC20(_token);
  } 
}
