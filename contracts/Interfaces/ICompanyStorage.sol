// SPDX-License-Identifier: UNLICENSED
pragma solidity >= 0.8.0;


interface ICompanyStorage {
  
  function recordNewCompany(address _companyAddress, address _companyTokenAddress) external;
}