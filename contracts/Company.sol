//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";

import "./StreamRedirect.sol";

contract Company is ERC721, StreamRedirect, Ownable, KeeperCompatibleInterface {
  using Counters for Counters.Counter;
  Counters.Counter public _tokenIdTracker;
  address public companyToken;
  uint256 public vestingPeriod;
  string private _baseMetadataURI;

  struct Node {
    uint256 nodeId;
    uint256 tokenId;
    uint256 expirationDate;
    uint256 prevNode;
    uint256 nextNode;
  }

  // tokenIds => nodeIds
  mapping(uint256 => Node) nodesFromTokenId;
  mapping(uint256 => Node) nodesFromNodeId;

  uint256 head = 0; // nodeId of head
  uint256 tail = 0; // nodeId of tail
  uint256 currentNode = 1;

  function _calculateExpiration() internal view returns (uint256) {
    return block.timestamp + vestingPeriod * 365 days;
  }

  function push(uint256 _tokenId) public {
    Node memory newNode = Node(
      currentNode++, 
      _tokenId, 
      _calculateExpiration(),
      tail,
      0
    );
    tail = newNode.nodeId;
    nodesFromNodeId[newNode.nodeId] = newNode;
    nodesFromTokenId[newNode.tokenId] = newNode;
  }

  function remove(uint256 _tokenId) public {
    Node storage node = nodesFromTokenId[_tokenId];
    Node storage prevNode = nodesFromNodeId[node.prevNode];
    Node storage nextNode = nodesFromNodeId[node.nextNode];
    prevNode.nextNode = nextNode.nodeId;
    nextNode.prevNode = prevNode.nodeId;
  }

  constructor(
    string memory name_,
    string memory symbol_,
    address owner_,
    address companyToken_,
    string memory baseURI_,
    address host_,
    address superTokenFactory_,
    uint256 vestingPeriod_
  )
    ERC721(name_, symbol_)
    StreamRedirect(ISuperfluid(host_),ISuperTokenFactory(superTokenFactory_),companyToken_)
  {
    transferOwnership(owner_);
    companyToken = companyToken_;
    _baseMetadataURI = baseURI_;
    vestingPeriod = vestingPeriod_;
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

    if (from == address(0)) { 
      push(tokenId);
    } else if (to == address(0)) {
      remove(tokenId);
    }

    if (!(from == address(0) || to == address(0))){
      _changeReceiver(tokenId, to);
    }
  }


  function checkUpkeep(bytes calldata /* checkData */) external view override returns (bool upkeepNeeded, bytes memory /* performData */) {  
    Node storage nodeHead = nodesFromNodeId[head];
    upkeepNeeded = nodeHead.expirationDate <= block.timestamp;
  }

    function performUpkeep(bytes calldata /* performData */) external override {
      Node storage nodeHead = nodesFromNodeId[head];

      if (nodeHead.expirationDate <= block.timestamp) { // Revalidate upkeep 
        _burn(nodeHead.tokenId);
      }
    }

}