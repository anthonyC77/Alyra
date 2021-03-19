// SPDX-License-Identifier: GPL-3.0

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

pragma solidity =0.8.0;

contract Voting {
    
    event VoterRegistered(address voterAddress);
    event ProposalsRegistrationStarted();
    event ProposalsRegistrationEnded();
    event ProposalRegistered(uint proposalId);
    event VotingSessionStarted();
    event VotingSessionEnded();
    event Voted (address voter, uint proposalId);
    event VotesTallied();
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus
    newStatus);
    
    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint votedProposalId;
    }

    struct Proposal {
        string description;
        uint voteCount;
    }
    
    enum WorkflowStatus {
        RegisteringVoters,
        ProposalsRegistrationStarted,
        ProposalsRegistrationEnded,
        VotingSessionStarted,
        VotingSessionEnded,
        VotesTallied
    }
    
    WorkflowStatus status;
    
    Proposal[] Proposals;
    
    function voterRegister(address _address)  public {
        
        
        emit VoterRegistered(_address);
    }
    
    function StartProposalsRegistration() public{
        // if admin 
        //Proposals = new Proposal[];
        
        emit ProposalsRegistrationStarted();
    }
    
    function StopProposalsRegistration() public{
        // if admin 
         emit ProposalsRegistrationEnded();
    }
    
    function ProposeRecord(address _address, string memory _descriptionProposal) public {
        // une propsition par user ?
        Proposals.push(Proposal(_descriptionProposal, 0));
        uint proposalId = Proposals.length - 1;
        emit ProposalRegistered(proposalId);
    }
    
    
    function SartVote() public{
        status = WorkflowStatus.VotingSessionStarted;
        emit VotingSessionStarted();
    }
    
    function StopVote() public{
        status = WorkflowStatus.VotingSessionEnded;
        emit VotingSessionEnded();
    }
    
    function VoteUser(address _address, uint propoalId) public {
        // if already vote no require
        require(status ==  WorkflowStatus.VotingSessionStarted, "Error...");
        emit Voted(_address, propoalId);
    }
    
}
