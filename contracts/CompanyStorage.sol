//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {ISuperToken} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperToken.sol";


contract CompanyStorage is Ownable{

  address private companyFactoryAddress;
  
  struct companyInfo {
    address companyAddress;
    address companyTokenAddress;
    address companySuperTokenAddress;
    int256 numberOfActiveVestingStreams; 
  }

  mapping(address => companyInfo) public companyInfoFromAddress;

  address[] private companyList;

  // --- events --- 
  // event newCompanyCreated(
  //   address indexed creator,
  //   address deployedAddr,
  //   string name,
  //   address companyToken,
  //   string symbol,
  //   string baseURI
  // );


  // --- Dependencies setter --- 

  function setCompanyFactoryAddress(address _companyFactoryAddress) external onlyOwner {
    companyFactoryAddress = _companyFactoryAddress;
  }

  // --- External functions ---
   
  function recordNewCompanyAddressAndTokenAddress(address _companyAddress, address _companyTokenAddress) external {
    require(_isCompanyFactory(), "Caller is not company factory");

    companyInfoFromAddress[_companyAddress].companyAddress = _companyAddress;
    companyInfoFromAddress[_companyAddress].companyTokenAddress = _companyTokenAddress;
    companyInfoFromAddress[_companyAddress].numberOfActiveVestingStreams = 0;

    companyList.push(_companyAddress);
  }

  function setCompanySuperTokenAddress(address _superTokenAddress) external {
    address companyAddress = msg.sender;
    companyInfoFromAddress[companyAddress].companySuperTokenAddress = _superTokenAddress;
  }

  function updateCompanyNumberOfActiveStreams(int256 _updateValue) external {
    address companyAddress = msg.sender;
    companyInfoFromAddress[companyAddress].numberOfActiveVestingStreams += _updateValue;
  }

  // --- internal functions ---

  function _isCompanyFactory() internal view returns (bool) {
    return msg.sender == companyFactoryAddress;
  }
  
}