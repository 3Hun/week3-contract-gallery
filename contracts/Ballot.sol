// SPDX-License-Identifier: MIT
pragma solidity 0.8.37;

contract Ballot {
    struct Proposal {
        string name;
        uint256 voteCount;
    }

    address public immutable owner;
    uint256 public constant MAX_PROPOSALS = 20;
    uint256 public deadline;
    bool public votingStarted;

    Proposal[] private proposals;
    mapping(address => bool) public hasVoted;

    event ProposalAdded(uint256 indexed proposalId, string name);
    event VotingStarted(uint256 deadline);
    event VoteCast(address indexed voter, uint256 indexed proposalId);

    error NotOwner();
    error EmptyProposalName();
    error ProposalLimitReached();
    error InvalidProposal();
    error InvalidDuration();
    error NotEnoughProposals();
    error VotingAlreadyStarted();
    error VotingNotStarted();
    error VotingClosed();
    error VotingNotEnded();
    error AlreadyVoted();

    constructor() {
        owner = msg.sender;
    }

    function addProposal(string calldata name) external {
        if (msg.sender != owner) revert NotOwner();
        if (votingStarted) revert VotingAlreadyStarted();
        if (bytes(name).length == 0) revert EmptyProposalName();
        if (proposals.length >= MAX_PROPOSALS) revert ProposalLimitReached();

        uint256 proposalId = proposals.length;
        proposals.push(Proposal({name: name, voteCount: 0}));
        emit ProposalAdded(proposalId, name);
    }

    function startVoting(uint256 durationSeconds) external {
        if (msg.sender != owner) revert NotOwner();
        if (votingStarted) revert VotingAlreadyStarted();
        if (proposals.length < 2) revert NotEnoughProposals();
        if (durationSeconds == 0) revert InvalidDuration();

        deadline = block.timestamp + durationSeconds;
        votingStarted = true;
        emit VotingStarted(deadline);
    }

    function vote(uint256 proposalId) external {
        if (!votingStarted) revert VotingNotStarted();
        if (block.timestamp >= deadline) revert VotingClosed();
        if (proposalId >= proposals.length) revert InvalidProposal();
        if (hasVoted[msg.sender]) revert AlreadyVoted();

        hasVoted[msg.sender] = true;
        proposals[proposalId].voteCount += 1;
        emit VoteCast(msg.sender, proposalId);
    }

    function proposalCount() external view returns (uint256) {
        return proposals.length;
    }

    function getProposal(uint256 proposalId)
        external
        view
        returns (string memory name, uint256 voteCount)
    {
        if (proposalId >= proposals.length) revert InvalidProposal();
        Proposal storage proposal = proposals[proposalId];
        return (proposal.name, proposal.voteCount);
    }

    function winningProposal()
        external
        view
        returns (uint256 proposalId, string memory name, uint256 voteCount, bool tied)
    {
        if (!votingStarted || block.timestamp < deadline) revert VotingNotEnded();

        uint256 highestCount = proposals[0].voteCount;
        for (uint256 i = 1; i < proposals.length; ++i) {
            uint256 count = proposals[i].voteCount;
            if (count > highestCount) {
                highestCount = count;
                proposalId = i;
                tied = false;
            } else if (count == highestCount) {
                tied = true;
            }
        }

        return (proposalId, proposals[proposalId].name, highestCount, tied);
    }
}
