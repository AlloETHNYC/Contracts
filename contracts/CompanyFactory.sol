//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Company.sol";

contract CompanyFacotry {
  mapping(address => mapping(uint256 => address)) public companyMap;  
  mapping(address => uint256) public companyNumByCreator;
  address[] public allCompanies;
  event newCompanyCreated(
    address indexed creator,
    address indexed deployedAddr,
    string indexed name,
    address companyToken,
    string symbol,
    string baseURI_
  );
function createCompany(
    string calldata name_,
    string calldata symbol_,
    address companyToken_,
    string calldata baseURI_, 
    address host_, 
    address superTokenFactory_

  ) external returns (address newCompanyAddr) {
    uint256 index = companyNumByCreator[msg.sender];
    Company company = new Company(
      name_,
      symbol_,
      msg.sender,
      companyToken_,
      baseURI_, 
      host_,
      superTokenFactory_
    );
    newCompanyAddr = address(company);
    companyMap[msg.sender][index] = newCompanyAddr;
    allCompanies.push(newCompanyAddr);
    companyNumByCreator[msg.sender] = companyNumByCreator[msg.sender] + 1;

    emit newCompanyCreated(
      msg.sender,
      newCompanyAddr,
      name_,
      companyToken_,
      symbol_,
      baseURI_
    );
  }
  function allCompaniesLength() external view returns (uint256) {
    return allCompanies.length;
  }

  function getAllCompanies() external view returns (address[] memory) {
    return allCompanies;
  }

  function getCompaniesByCreator(address _creator)
    external
    view
    returns (address[] memory)
  {
    uint256 length = companyNumByCreator[_creator];
    address[] memory res = new address[](length);
    for (uint256 i = 0; i < length; i++) {
      res[i] = companyMap[_creator][i];
    }
    return res;
  }

}