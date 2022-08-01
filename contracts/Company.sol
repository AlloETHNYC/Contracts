//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {ICompany} from "./Interfaces/ICompany.sol";
import {IVestingManager} from "./Interfaces/IVestingManager.sol";

import "./StreamRedirect.sol";


contract Company is ERC721, StreamRedirect, Ownable, ICompany {

  IVestingManager public VESTING_MANAGER;
  address immutable public COMPANY_FACTORY_ADDRESS;

  // NFT stuff
  uint256 private tokenIdTracker = 0;
  string private baseMetadataURI;

  constructor(
    string memory _name,
    string memory _symbol,
    address _owner,
    address _companyToken,
    string memory _baseURI,
    address _host,
    address _superTokenFactory
  )
    ERC721(
      _name, 
      _symbol
    )
    StreamRedirect(
      ISuperfluid(_host), 
      _superTokenFactory , 
      _companyToken
    )
  {
    transferOwnership(_owner);
    baseMetadataURI = _baseURI;
    COMPANY_FACTORY_ADDRESS = msg.sender;
  }

  // ---dependencies setters -- 

  function setVestingManagerAddress(address _vestingManagerAddress) external {
    require(
      _isCallerCompanyFactory(),
      "Caller is not Company Factory"
    );
    
    require( // Make sure Vesting manager has not been set already
      address(VESTING_MANAGER) == address(0), 
      "Vesting manager address is already set"
    );
    require( // Make sure no streams have already been created with recording token in vesting manager
      tokenIdTracker == 0, 
      "Vesting streams have already been created"
    );

    VESTING_MANAGER = IVestingManager(_vestingManagerAddress);
  }

  // --- External functions --- 

  function deposit(uint256 amount) external override onlyOwner {
    IERC20(COMPANY_TOKEN).transferFrom(msg.sender,address(this),amount);
    _wrap(amount);
  }


  function createTokenVestingStreamNFT(address _vestingReceiver, int96 _flowrate, uint256 _totalVestingAmountInWei, uint256 _vestingPeriodInSeconds) external override onlyOwner {
    require( // Make sure vesting reciever address is valid
      _vestingReceiver != address(0), 
      "Receiver can't be zero address"
    );
    require( // Note: Check this later
      balanceOf(_vestingReceiver) == 0, 
      "Receiver already has an allocation"
    );
    require( // make sure vesting stream flowrate is greater than 0
      _flowrate > 0, 
      "flowrate must be greater than 0"
    );

    // Get new NFT's tokenId
    uint256 tokenId = tokenIdTracker++; 

    // Mint NFT to vesting receiver
    _safeMint(_vestingReceiver, tokenId);

    // create vesting stream
    _createStream(_vestingReceiver, _flowrate);

    // Update VestingManager
    VESTING_MANAGER.recordNewVestingStream(
      /*_tokenId=*/tokenId, 
      /*_vestingAmount=*/_totalVestingAmountInWei, 
      /*_startTimestamp=*/block.timestamp, 
      /*_expirationTimestamp=*/block.timestamp + _vestingPeriodInSeconds
    );
  }

  function deleteTokenVestingStreamNFT(uint256 tokenId) external override onlyOwner {
    require(_exists(tokenId), "TokenId does not exist");
    // vesting stream will be deleted in beforeTransfer hook
    _burn(tokenId);
  }

  function deleteExpiredTokenVestingStreamNFT(uint256 tokenId) external override {
    require(
      _isCallerVestingManager(), 
      "Caller is not vesting manager"
    );
    require(_exists(tokenId), "TokenId does not exist");
    // vesting stream will be deleted in beforeTransfer hook
    _burn(tokenId);
  }

  // --- Internal functions ---

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal override {

    if (from == address(0)) { 
      return;
    } else if (to == address(0)) {
      _deleteStream(from);
      VESTING_MANAGER.removeExistingVestingStream(tokenId);
    }

    _changeReceiver(tokenId, to);
  }

  function _baseURI() internal view override returns (string memory) {
    return baseMetadataURI;
  }

  function _isCallerCompanyFactory() internal view returns (bool) {
    return msg.sender == COMPANY_FACTORY_ADDRESS;
  }

  function _isCallerVestingManager() internal view returns (bool) {
    return msg.sender == address(VESTING_MANAGER);
  }

}