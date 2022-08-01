// SPDX-License-Identifier: UNLICENSED
pragma solidity >= 0.8.0;


interface IVestingManager {

  function recordNewVestingStream(uint256 _tokenId, uint256 _vestingAmount, uint256 _startTimestamp, uint256 _expirationTimestamp) external;

  function removeExistingVestingStream(uint256 _tokenId) external;

}