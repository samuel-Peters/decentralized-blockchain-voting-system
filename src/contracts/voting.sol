// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title VoteRegistry - store vote hashes and emit events for audits
contract VoteRegistry {
    address public owner;

    event VoteRecorded(address indexed recorder, string voteHash, uint256 timestamp);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    /// @notice store a vote hash and emit event
    /// @param _voteHash the hashed vote string
    function storeVote(string calldata _voteHash) external returns (bool) {
        // Emit the hash so it is publicly recorded on-chain
        emit VoteRecorded(msg.sender, _voteHash, block.timestamp);
        return true;
    }
}
