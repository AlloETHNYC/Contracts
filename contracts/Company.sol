//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./StreamRedirect.sol";

contract Company is ERC721, StreamRedirect, Ownable {
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIdTracker;
  address public tokenAddress;
  string private _baseMetadataURI;

   constructor(
    string memory name_,
    string memory symbol_,
    address owner_,
    address tokenAddress_,
    string memory baseURI_,
    ISuperfluid host_,
    ISuperTokenFactory superTokenFactory_
  )
    ERC721(name_, symbol_)
    StreamRedirect(host_,superTokenFactory_,tokenAddress_)
  {
    transferOwnership(owner_);
    tokenAddress = tokenAddress_;
    _baseMetadataURI = baseURI_;
  }

  function _baseURI() internal view override returns (string memory) {
    return _baseMetadataURI;
  }

  function addReceiver(address receiver) public onlyOwner {
    require(receiver != address(0), "Receiver can't be zero address");
    require(balanceOf(receiver) == 0, "Receiver already has an allocation");

    uint256 tokenId = _tokenIdTracker.current();
    _safeMint(receiver, _tokenIdTracker.current());
    _tokenIdTracker.increment();
    //Open up a stream
    //OpenStream(tokenAddress,this.address, receiver, flowRate)
  }

  function remove(uint256 tokenId) public onlyOwner {
    require(_exists(tokenId), "TokenId does not exist");
    //Close the Stream
    //CloseStream()
    _burn(tokenId);
  }

  function _beforeTokenTransfer(
    address /*from*/,
    address to,
    uint256 /*tokenId*/
  ) internal override {
      // _changeReceiver(to);
  }

}