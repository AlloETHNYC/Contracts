//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "solidity-linked-list/contracts/StructuredLinkedList.sol";

contract Test{
  using StructuredLinkedList for StructuredLinkedList.List;
  StructuredLinkedList.List list;
  constructor(){
    list.pushBack(1);
    list.pushBack(2);
    list.pushBack(3);
    list.pushBack(4);
  }

   function test() external view  returns (uint temp) {
      temp = list.getValue(0);
      // upkeepNeeded = (block.timestamp - lastTimeStamp) > interval;
      // We don't use the checkData in this example. The checkData is defined when the Upkeep was registered.
  }
}