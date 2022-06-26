//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Company.sol";

contract CompanyFactory {

  // mapping(address => mapping(uint256 => address)) public companyMap; 

  // mapping(address => uint256) public companyNumByCreator;
  
  // address[] public allCompanies;

  struct MetadataInfo {
    uint256 vestingPeriod;
    string baseURI;
    string description;
  }

  event newCompanyCreated(
    address indexed creator,
    address indexed deployedAddr,
    string name,
    address companyToken,
    string symbol,
    string baseURI,
    string description,
    uint256 vestingPeriod
  );

  function createCompany(
    string calldata name_,
    string calldata symbol_,
    address companyToken_,
    address host_, 
    address superTokenFactory_,
    MetadataInfo calldata metadataInfo_
  ) external returns (address newCompanyAddr) {
    // uint256 index = companyNumByCreator[msg.sender];
    Company company = new Company(
      name_,
      symbol_,
      msg.sender,
      companyToken_,
      metadataInfo_.baseURI, 
      host_,
      superTokenFactory_,
      metadataInfo_.vestingPeriod
    );
    newCompanyAddr = address(company);
    // companyMap[msg.sender][index] = newCompanyAddr;
    // allCompanies.push(newCompanyAddr);
    // companyNumByCreator[msg.sender] = companyNumByCreator[msg.sender] + 1;

    emit newCompanyCreated(
      msg.sender,
      newCompanyAddr,
      name_,
      companyToken_,
      symbol_,
      metadataInfo_.baseURI,
      metadataInfo_.description,
      metadataInfo_.vestingPeriod
    );
  }
  // function allCompaniesLength() external view returns (uint256) {
  //   return allCompanies.length;
  // }

  // function getAllCompanies() external view returns (address[] memory) {
  //   return allCompanies;
  // }

  // function getCompaniesByCreator(address _creator)
  //   external
  //   view
  //   returns (address[] memory)
  // {
  //   uint256 length = companyNumByCreator[_creator];
  //   address[] memory res = new address[](length);
  //   for (uint256 i = 0; i < length; i++) {
  //     res[i] = companyMap[_creator][i];
  //   }
  //   return res;
  // }

}