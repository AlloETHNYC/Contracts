// SPDX-License-Identifier: UNLICENSED
pragma solidity >= 0.8.0;

import {KeeperCompatible} from "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";

import {ICompany} from "./Interfaces/ICompany.sol";

import {IVestingManager} from "./Interfaces/IVestingManager.sol";

contract VestingManager is KeeperCompatible, IVestingManager {

  ICompany immutable MANAGED_COMPANY;

  struct VestingStreamNode {
    // Stream info
    uint256 tokenId;
    uint256 vestingAmount;
    uint256 startTimestamp;
    uint256 expirationTimestamp;
    // linked list info
    uint256 nodeId;
    uint256 prevNodeId;
    uint256 nextNodeId;
  }

  // tokenIds => nodeIds
  mapping(uint256 => VestingStreamNode) streamingNodesFromTokenId;
  mapping(uint256 => VestingStreamNode) streamingNodesFromNodeId;

  uint256 headNodeId = 0; // nodeId of head
  uint256 tailNodeId = 0; // nodeId of tail
  uint256 currentNodeId = 1;

  constructor(address _companyAddress) {
    MANAGED_COMPANY = ICompany(_companyAddress);
  }  

  function recordNewVestingStream(uint256 _tokenId, uint256 _vestingAmount, uint256 _startTimestamp, uint256 _expirationTimestamp) external override {
    VestingStreamNode memory newVestingStreamNode = VestingStreamNode(
      /*tokenId=*/_tokenId, 
      /*vestingAmount=*/_vestingAmount, 
      /*startTimestamp=*/_startTimestamp, 
      /*expirationTimestamp=*/_expirationTimestamp,
      /*nodeId=*/currentNodeId++, 
      // Position in list is unknown currently
      /*prevNodeId=*/0,
      /*nextNodeId=*/0
    );

    // Add new streaming node to mappings
    streamingNodesFromNodeId[newVestingStreamNode.nodeId] = newVestingStreamNode;
    streamingNodesFromTokenId[newVestingStreamNode.tokenId] = newVestingStreamNode;

    _addNewVestingStreamToList(newVestingStreamNode.nodeId);
  }

  function removeExistingVestingStream(uint256 _tokenId) external override {
    VestingStreamNode storage removedNode = streamingNodesFromTokenId[_tokenId];
    VestingStreamNode storage prevNode = streamingNodesFromNodeId[removedNode.prevNodeId];
    VestingStreamNode storage nextNode = streamingNodesFromNodeId[removedNode.nextNodeId];
    prevNode.nextNodeId = nextNode.nodeId;
    nextNode.prevNodeId = prevNode.nodeId;
    
    // Corner cases
    if(_isNodeTail(removedNode)) {
      tailNodeId = prevNode.nodeId;
    }
    if (_isNodeHead(removedNode)) {
      headNodeId = nextNode.nodeId;
    }
  }

  // --- internal linkedList functions --- 

  function _addNewVestingStreamToList(uint256 _newVestingStreamNodeId) internal {
    VestingStreamNode storage newVestingStreamingNode = streamingNodesFromNodeId[_newVestingStreamNodeId];
    if (_isExpirationLaterThanOrEqualToCurrentTailExpiration(newVestingStreamingNode.expirationTimestamp)) {
      _push(newVestingStreamingNode);
      return;
    } else {
      _insert(newVestingStreamingNode);
      return;
    }
  }

  function _insert(VestingStreamNode storage _newVestingStreamNode) internal {

    // find spot to put new vesting stream node
    VestingStreamNode storage currNode = streamingNodesFromNodeId[tailNodeId];
    while (currNode.expirationTimestamp < _newVestingStreamNode.expirationTimestamp) {
      currNode = streamingNodesFromNodeId[currNode.nextNodeId];
    }

    // Get neighbor nodes
    VestingStreamNode storage prevNode = streamingNodesFromNodeId[currNode.prevNodeId];
    VestingStreamNode storage nextNode = currNode;

    // Insert new node
    _newVestingStreamNode.prevNodeId = prevNode.nodeId;
    _newVestingStreamNode.nextNodeId = nextNode.nodeId;

    prevNode.nextNodeId = _newVestingStreamNode.nodeId;

    nextNode.prevNodeId = _newVestingStreamNode.nodeId;
  } 

  function _push(VestingStreamNode storage _newVestingStreamNode) internal {
    tailNodeId = _newVestingStreamNode.nodeId;
    streamingNodesFromNodeId[_newVestingStreamNode.nodeId] = _newVestingStreamNode;
    streamingNodesFromTokenId[_newVestingStreamNode.tokenId] = _newVestingStreamNode;
  }

  function _isExpirationLaterThanOrEqualToCurrentTailExpiration(uint256 _newStreamExpirationTimestamp) internal view returns (bool) {
    VestingStreamNode storage tailNode = streamingNodesFromNodeId[tailNodeId];
    return _newStreamExpirationTimestamp >= tailNode.expirationTimestamp;
  }

  function _isNodeTail(VestingStreamNode storage _vestingStreamNode) internal view returns (bool) {
    return _vestingStreamNode.nodeId == tailNodeId;
  }

  function _isNodeHead(VestingStreamNode storage _vestingStreamNode) internal view returns (bool) {
    return _vestingStreamNode.nodeId == headNodeId;
  }

  // --- Chainlink Keeper functions --- 

  function checkUpkeep(bytes calldata /* checkData */) external view override returns (bool upkeepNeeded, bytes memory /* performData */) {  
    upkeepNeeded = _isHeadVestingStreamExpired();
  }

  function performUpkeep(bytes calldata /* performData */) external override {
    if (_isHeadVestingStreamExpired()) { // Revalidate upkeep for safety
      VestingStreamNode storage nodeHead = streamingNodesFromNodeId[headNodeId];
      MANAGED_COMPANY.deleteExpiredTokenVestingStreamNFT(nodeHead.tokenId);
    }
  }

  // --- internal functions --- 

  function _isHeadVestingStreamExpired() internal view returns (bool) {
    VestingStreamNode storage nodeHead = streamingNodesFromNodeId[headNodeId];
    return nodeHead.expirationTimestamp <= block.timestamp;
  }
}