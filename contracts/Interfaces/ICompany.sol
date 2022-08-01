//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface ICompany {

  function deposit(uint256 amount) external;

  function createTokenVestingStreamNFT(address _vestingReceiver, int96 _flowrate, uint256 _totalVestingAmount, uint256 _vestingPeriod) external;

  function deleteTokenVestingStreamNFT(uint256 tokenId) external;

  function deleteExpiredTokenVestingStreamNFT(uint256 tokenId) external;
}