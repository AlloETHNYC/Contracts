// SPDX-License-Identifier: UNLICENSED
pragma solidity >= 0.8.0;

import {ISuperfluid, ISuperToken, ISuperApp, ISuperAgreement, SuperAppDefinitions} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol"; //"@superfluid-finance/ethereum-monorepo/packages/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";
import {CFAv1Library} from "@superfluid-finance/ethereum-contracts/contracts/apps/CFAv1Library.sol";
import {IConstantFlowAgreementV1} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/agreements/IConstantFlowAgreementV1.sol";
import {SuperAppBase} from "@superfluid-finance/ethereum-contracts/contracts/apps/SuperAppBase.sol";
import {ISuperTokenFactory} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperTokenFactory.sol";

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";


contract StreamRedirect is SuperAppBase {

  using CFAv1Library for CFAv1Library.InitData;
    
  //initialize cfaV1 variable
  CFAv1Library.InitData public cfaV1;

  ISuperTokenFactory immutable _superTokenFactory; 

  ISuperToken immutable _superCompanyToken; // company token (super version)

  address immutable _companyToken; // company token (regular version) 

  IERC721 immutable _companyNFT;  // NFT collection of company allocation

  constructor(
    ISuperfluid host, 
    ISuperTokenFactory superTokenFactory,
    address companyToken
  ) {
  
    //initialize InitData struct, and set equal to cfaV1
    cfaV1 = CFAv1Library.InitData(
      host,
      IConstantFlowAgreementV1(
      address(host.getAgreementClass(
          keccak256("org.superfluid-finance.agreements.ConstantFlowAgreement.v1")
        ))
      )
    );

    // Store regular company token
    _companyToken = companyToken;

    // Create token wrapper and set superToken address
    _superTokenFactory = superTokenFactory;
    _superCompanyToken = _superTokenFactory.createERC20Wrapper(
      IERC20(companyToken),
      uint8(18), // decimals
      ISuperTokenFactory.Upgradability.NON_UPGRADABLE,   // upgradability
      IERC20Metadata(companyToken).name(),  // token name (Note: add super to string)
      IERC20Metadata(companyToken).symbol() // token symbol (Note: add x to symbol)
    );

    // // Wrap tokens (Note: approve first!)

    // _companyToken.upgrade(amountOfTokens);

    // _companyToken;

    _companyNFT = IERC721(address(this));

  }

  function _wrap(uint256 _amountOfTokens) internal {
    // Verify balance of tokens
    require(IERC20(_companyToken).balanceOf(address(this)) == _amountOfTokens, "Contract does not have correct amount of tokens");

    // Wrap tokens
    IERC20(_companyToken).approve(address(_superCompanyToken), _amountOfTokens);
    _superCompanyToken.upgrade(_amountOfTokens);

    // Verify successful wrap
  }

  function _createStream(address _receiver, int96 _flowrate) internal {
    // Note: Will probably need to verify that a stream doesn't already exist
    cfaV1.createFlow(
      _receiver,
      _superCompanyToken,
      _flowrate
    );  // Note: can include option data. Maybe to include the allocation NFT info or something
  }

  function _deleteStream(address _receiver) internal {
    cfaV1.deleteFlow(address(this), _receiver, _superCompanyToken);
  }

  function _changeReceiver(uint256 _allocationId, address _newReceiver) internal {

    require(_newReceiver != address(0), "New receiver is zero address");  

    address receiver = _companyNFT.ownerOf(_allocationId);  // token id must exist 

    if (_newReceiver == receiver) return; 
    
    // Get flowrate of existing allocation
    (, int96 outFlowRate, , ) = cfaV1.cfa.getFlow(
      _superCompanyToken,
      address(this),
      receiver
    ); //CHECK: unclear what happens if flow doesn't exist.

    if (outFlowRate > 0) {
      cfaV1.deleteFlow(address(this), receiver, _superCompanyToken);
      cfaV1.createFlow(
        _newReceiver,
        _superCompanyToken,
        outFlowRate
      );  // Note: can include option data. Maybe to include the allocation NFT info or something
    }
  }

}