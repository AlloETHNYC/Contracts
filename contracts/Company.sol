//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./StreamRedirect.sol";

contract Company is ERC721, StreamRedirect, Ownable {
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIdTracker;
  address public companyToken;
  string private _baseMetadataURI;

   constructor(
    string memory name_,
    string memory symbol_,
    address owner_,
    address companyToken_,
    string memory baseURI_,
    address host_,
    address superTokenFactory_
  )
    ERC721(name_, symbol_)
    StreamRedirect(ISuperfluid(host_),ISuperTokenFactory(superTokenFactory_),companyToken_)
  {
    transferOwnership(owner_);
    companyToken = companyToken_;
    _baseMetadataURI = baseURI_;
  }

  function _baseURI() internal view override returns (string memory) {
    return _baseMetadataURI;
  }

  function deposit(uint256 amount) public onlyOwner {
    IERC20(companyToken).transferFrom(msg.sender,address(this),amount);
    _wrap(amount);
  }


  function addReceiver(address receiver, int96 flowrate) public onlyOwner {
    require(receiver != address(0), "Receiver can't be zero address");
    require(balanceOf(receiver) == 0, "Receiver already has an allocation");

    uint256 tokenId = _tokenIdTracker.current();
    _safeMint(receiver, tokenId);
    _tokenIdTracker.increment();
    //Open up a stream
    //OpenStream(companyToken,this.address, receiver, flowRate)
    _createStream(receiver, flowrate);
  }

  function removeReceiver(uint256 tokenId) public onlyOwner {
    require(_exists(tokenId), "TokenId does not exist");
    //deleteStream will be handled in burn when _changeReceiver is called
    _burn(tokenId);
    _deleteStream(ownerOf(tokenId));
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal override {
    if (!(from == address(0) || to == address(0))){
      _changeReceiver(tokenId, to);
    }
  }

}