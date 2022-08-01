// SPDX-License-Identifier: UNLICENSED
pragma solidity >= 0.8.0;

import "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";
import "@superfluid-finance/ethereum-contracts/contracts/apps/CFAv1Library.sol";
import "@superfluid-finance/ethereum-contracts/contracts/interfaces/agreements/IConstantFlowAgreementV1.sol";
import "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperTokenFactory.sol";
import "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperToken.sol";

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract StreamRedirect {

  using CFAv1Library for CFAv1Library.InitData;
    
  //initialize cfaV1 variable
  CFAv1Library.InitData public cfaV1;

  ISuperTokenFactory immutable SUPER_TOKEN_FACTORY; 

  ISuperToken immutable SUPER_COMPANY_TOKEN; // company token (super version)

  IERC20Metadata immutable COMPANY_TOKEN; // company token (regular version) 

  IERC721 immutable COMPANY_NFT;  // NFT collection of company allocation

  // Events
  event tokensWrapped(uint256 amount);
  event tokensUnwrapped(uint256 amount, address indexed receiver);
  event allocationStreamCreated(address indexed receiver, int96 flowrate, uint256 creationTimestamp);
  event allocationStreamRedirected(address oldReceiver, address newReceiver);
  event allocationStreamBurned(address indexed receiver);


  constructor(
    ISuperfluid _host, 
    address _superTokenFactory,
    address _companyToken
  ) {
  
    //initialize InitData struct, and set equal to cfaV1
    cfaV1 = CFAv1Library.InitData(
      _host,
      IConstantFlowAgreementV1(
      address(_host.getAgreementClass(
          keccak256("org.superfluid-finance.agreements.ConstantFlowAgreement.v1")
        ))
      )
    );

    // Store regular company token
    COMPANY_TOKEN = IERC20Metadata(_companyToken);

    // Create token wrapper and set superToken address
    SUPER_TOKEN_FACTORY = ISuperTokenFactory(_superTokenFactory);

    SUPER_COMPANY_TOKEN = SUPER_TOKEN_FACTORY.createERC20Wrapper(
      COMPANY_TOKEN,
      uint8(18), // decimals
      ISuperTokenFactory.Upgradability.NON_UPGRADABLE,   // upgradability
      string(abi.encodePacked("Super ", COMPANY_TOKEN.name())),
      string(abi.encodePacked(COMPANY_TOKEN.symbol(), "x"))
    );

    COMPANY_NFT = IERC721(address(this));

  }

  // --- External functions

  function unwrap(uint256 _amountOfTokens) public {
    (int256 userBalance, , ) = ISuperToken(SUPER_COMPANY_TOKEN).realtimeBalanceOf(msg.sender, block.timestamp);
    require(userBalance >= int256(_amountOfTokens), "Amount exceeds user's balance");

    SUPER_COMPANY_TOKEN.downgrade(_amountOfTokens);
    IERC20(COMPANY_TOKEN).transfer(msg.sender, _amountOfTokens);

    emit tokensUnwrapped(_amountOfTokens, msg.sender);
  }

  // --- Internal functions --- 

  function _wrap(uint256 _amountOfTokens) internal {
    // Verify balance of tokens
    require(COMPANY_TOKEN.balanceOf(address(this)) == _amountOfTokens, "Contract does not have correct amount of tokens");

    // Wrap tokens
    IERC20(COMPANY_TOKEN).approve(address(SUPER_COMPANY_TOKEN), _amountOfTokens);
    SUPER_COMPANY_TOKEN.upgrade(_amountOfTokens);

    // Verify successful wrap

    emit tokensWrapped(_amountOfTokens);
  }

  function _createStream(address _receiver, int96 _flowrate) internal {
    // Note: Will probably need to verify that a stream doesn't already exist
    cfaV1.createFlow(
      _receiver,
      SUPER_COMPANY_TOKEN,
      _flowrate
    );  // Note: can include option data. Maybe to include the allocation NFT info or something
    emit allocationStreamCreated(_receiver, _flowrate, block.timestamp);
  }

  function _deleteStream(address _receiver) internal {
    cfaV1.deleteFlow(address(this), _receiver, SUPER_COMPANY_TOKEN);
    emit allocationStreamBurned(_receiver);
  }

  function _changeReceiver(uint256 _allocationId, address _newReceiver) internal {

    require(_newReceiver != address(0), "New receiver is zero address");  

    address receiver = COMPANY_NFT.ownerOf(_allocationId);  // token id must exist 

    if (_newReceiver == receiver) return; 
    
    // Get flowrate of existing allocation
    (, int96 outFlowRate, , ) = cfaV1.cfa.getFlow(
      SUPER_COMPANY_TOKEN,
      address(this),
      receiver
    ); //CHECK: unclear what happens if flow doesn't exist.

    if (outFlowRate > 0) {
      cfaV1.deleteFlow(address(this), receiver, SUPER_COMPANY_TOKEN);
      cfaV1.createFlow(
        _newReceiver,
        SUPER_COMPANY_TOKEN,
        outFlowRate
      );  // Note: can include option data. Maybe to include the allocation NFT info or something
    }

    emit allocationStreamRedirected(receiver, _newReceiver);
  }

  // --- getter functions ---
  
  // function getStreamInfo(address _tokenOwner) external view returns (uint256, int96, uint256, uint256) {
  //   // Get flowrate of existing allocation
  //   (uint256 timestamp, int96 outFlowRate, uint256 deposit, uint256 owedDeposit) = cfaV1.cfa.getFlow(
  //     SUPER_COMPANY_TOKEN,
  //     address(this),
  //     _tokenOwner
  //   ); //CHECK: unclear what happens if flow doesn't exist.

  //   return (timestamp, outFlowRate, deposit, owedDeposit);
  // }

}