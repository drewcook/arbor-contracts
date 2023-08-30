//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Semaphore} from "@semaphore/Semaphore.sol";
import {SemaphoreGroups} from "@semaphore/base/SemaphoreGroups.sol";
import {ISemaphoreVerifier} from "@semaphore/interfaces/ISemaphoreVerifier.sol";
import {ISemaphore} from "@semaphore/interfaces/ISemaphore.sol";
import {Counters} from "@openzeppelin/utils/Counters.sol";
import {SafeMath} from "@openzeppelin/utils/math/SafeMath.sol";

/// @title StemQueue contract.
/// @dev The following code is just a example to show how Semaphore con be used.
/// @dev StemQueue holds the votes around the stems within each project's stem queue
contract StemQueue is Semaphore.SemaphoreGroups {
    using Counters for Counters.Counter;

    // Local counter to keep track of groups
    Counters.Counter private _currentGroupId;

    // A new vote is published every time a user's proof is validated.
    event NewVote(bytes32 vote);

    // Voters are identified by a Merkle root.
    // The offchain Merkle tree contains the voters' identity commitments.
    uint256 public voters;

    // The external verifier used to verify Semaphore proofs.
    IVerifier public verifier;

    /// @dev Gets a group id and returns the group admin address.
    mapping(uint256 => address) public groupAdmins;

    // /// @dev Gets a group id and returns the stem ids with thier votes
    // mapping(uint256 => uint256[]) public groupStems;

    // /// @dev Gets a stem id and returns the number of votes it has.
    mapping(bytes32 => Counters.Counter) public stemVoteCounts;

    /// @dev Gets a nullifier hash and returns true or false.
    /// It is used to prevent double-voting.
    mapping(uint256 => bool) internal nullifierHashes;

    /// @dev Emitted when an admin is assigned to a group.
    /// @param groupId: Id of the group.
    /// @param oldAdmin: Old admin of the group.
    /// @param newAdmin: New admin of the group.
    event GroupAdminUpdated(uint256 indexed groupId, address indexed oldAdmin, address indexed newAdmin);

    /// @dev Checks if the group admin is the transaction sender.
    /// @param groupId: Id of the group.
    modifier onlyGroupAdmin(uint256 groupId) {
        require(groupAdmins[groupId] == _msgSender(), "Semaphore: caller is not the group admin");
        _;
    }

    constructor(uint256 _voters, address _verifier) {
        voters = _voters;
        verifier = IVerifier(_verifier);
    }

    // function getProjectGroup(uint256 groupId) external returns (IncrementalTreeData calldata) {
    // 	return groups[groupId];
    // }

    /// @dev Allow anyone to create a new group
    /// @param depth: Depth of the tree.
    /// @param zeroValue: Zero value of the tree.
    function createProjectGroup(uint8 depth, uint256 zeroValue, address admin) external {
        // Increment groupId then use
        _currentGroupId.increment();
        uint256 groupId = _currentGroupId.current();
        _createGroup(groupId, depth, zeroValue);
        groupAdmins[groupId] = admin;
        emit GroupAdminUpdated(groupId, address(0), admin);
    }

    /// @dev Allow anyone to add themselves to ta group
    /// @param groupId: Id of the group.
    /// @param identityCommitment: The identity commitment for the voter
    function addMemberToProjectGroup(uint256 groupId, uint256 identityCommitment) external {
        _addMember(groupId, identityCommitment);
    }

    /// @dev Allow only group admin to remove
    /// @dev Removes an identity commitment from an existing group. A proof of membership is
    /// needed to check if the node to be deleted is part of the tree.
    /// @param groupId: Id of the group.
    /// @param identityCommitment: Existing identity commitment to be deleted.
    /// @param proofSiblings: Array of the sibling nodes of the proof of membership.
    /// @param proofPathIndices: Path of the proof of membership.
    function removeMemberFromProjectGroup(
        uint256 groupId,
        uint256 identityCommitment,
        uint256[] calldata proofSiblings,
        uint8[] calldata proofPathIndices
    ) external onlyGroupAdmin(groupId) {
        _removeMember(groupId, identityCommitment, proofSiblings, proofPathIndices);
    }

    /// @dev Only users who create valid proofs can vote.
    /// @dev The contract owner must only send the transaction and they will not know anything about the identity of the voters.
    /// @dev The external nullifier is in this example the root of the Merkle tree.
    function vote(
        bytes32 _vote,
        uint256 groupId,
        uint256 externalNullifier,
        uint256 _nullifierHash,
        uint256[8] calldata _proof
    ) external {
        require(!nullifierHashes[_nullifierHash], "You can not use the same nullifier twice");

        uint256 root = getMerkleTreeRoot(groupId);
        _verifyProof(_vote, root, _nullifierHash, externalNullifier, _proof, verifier);

        // Prevent double-voting (nullifierHash = hash(stemId + identityNullifier)).
        // Every user can vote once.
        nullifierHashes[_nullifierHash] = true;

        // Update the vote count for the given stem
        // This would be 0 for a non-existant key in the mapping
        stemVoteCounts[_vote].increment();

        emit NewVote(_vote);
    }
}
