```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Voting {
    mapping(string => bool) public voteHashes;

    function storeVote(string memory hash) public {
        voteHashes[hash] = true;
    }

    function verifyVote(string memory hash) public view returns (bool) {
        return voteHashes[hash];
    }
}