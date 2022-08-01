//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Company} from "./Company.sol";
import {VestingManager} from "./VestingManager.sol";

import {ICompanyStorage} from "./Interfaces/ICompanyStorage.sol";


contract CompanyFactory {

  ICompanyStorage immutable COMPANY_STORAGE;

  constructor(address _companyStorageAddress) {
    COMPANY_STORAGE = ICompanyStorage(_companyStorageAddress);
  }

  function createCompany(
    string calldata _name,
    string calldata _symbol,
    address _companyToken,
    address _host, 
    address _superTokenFactory,
    string calldata _baseURI
  ) external returns (address) {

    // Deploy new company
    Company newCompany = new Company(
      _name,
      _symbol,
      msg.sender,
      _companyToken,
      _baseURI, 
      _host,
      _superTokenFactory
    );
    address newCompanyAddress = address(newCompany);

    // Store new company address in companyStorage
    COMPANY_STORAGE.recordNewCompany(newCompanyAddress, _companyToken);

    // Deploy vesting manager for company
    VestingManager companyVestingManager = new VestingManager(newCompanyAddress);
    address companyVestingManagerAddress = address(companyVestingManager);

    // Set vesting manager for new company
    newCompany.setVestingManagerAddress(companyVestingManagerAddress);
  }

}