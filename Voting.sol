// SPDX-License-Identifier: GPL-3.0

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

pragma solidity =0.8.0;

contract Voting is Ownable {
    
    uint winningProposalId;
    mapping(address=> Voter) private _whitelist;
    mapping(address=> bool) private _Proposers;
    Proposal[] Proposals;
    
    
    event VoterRegistered(address voterAddress);
    event ProposalsRegistrationStarted();
    event ProposalsRegistrationEnded();
    event ProposalRegistered(uint proposalId);
    event VotingSessionStarted();
    event VotingSessionEnded();
    event Voted (address voter, uint proposalId);
    event VotesTallied();
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);
    
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
    
    WorkflowStatus status = WorkflowStatus.RegisteringVoters;
    
    // Admin actions
    // --------------------------------------------------------------------------------------------------------------
    function voterRegister(address _address) public onlyOwner {
        require(status ==  WorkflowStatus.RegisteringVoters, "The voting registering is ended");
        require(!_whitelist[_address].isRegistered, "User already registred");
        
        require(status ==  WorkflowStatus.RegisteringVoters, "The voting registering is ended");
        
        Voter memory voter = Voter(true, false, 0);
        _whitelist[_address] = voter;
        _Proposers[_address] = false;
        emit VoterRegistered(_address);
    }
    
    function  AdminActions(WorkflowStatus _status) public onlyOwner{
        
        if(_status == WorkflowStatus.ProposalsRegistrationStarted) {
            require(status ==  WorkflowStatus.RegisteringVoters,"Users not registered yet");
            StartProposalsRegistration();
        }
        else if(_status == WorkflowStatus.ProposalsRegistrationEnded){
            require(status ==  WorkflowStatus.ProposalsRegistrationStarted,"Proposal session not started");
            StopProposalsRegistration();
        }  
        else if(_status == WorkflowStatus.VotingSessionStarted){
            require(status ==  WorkflowStatus.ProposalsRegistrationEnded,"Proposal session not ended");
            StartVote();
        } 
        else if(_status == WorkflowStatus.VotingSessionEnded){
            require(status ==  WorkflowStatus.VotingSessionStarted,"voting session not started");
            StopVote();
        }
         else if(_status == WorkflowStatus.VotesTallied){
             require(status ==  WorkflowStatus.VotingSessionEnded,"voting session not ended");
             CountProposals();
         }
            
        emit WorkflowStatusChange(_status, status);
        status = _status;
    }
    
    function StartProposalsRegistration() private{
        status = WorkflowStatus.ProposalsRegistrationStarted;
        emit ProposalsRegistrationStarted();
        emit WorkflowStatusChange(WorkflowStatus.RegisteringVoters,WorkflowStatus.ProposalsRegistrationStarted);
    }
    
    function StopProposalsRegistration() private{
         status = WorkflowStatus.ProposalsRegistrationEnded;
         emit ProposalsRegistrationEnded();
         emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationStarted,WorkflowStatus.ProposalsRegistrationEnded);
    }
    
    function StartVote() private{
        require(status == WorkflowStatus.RegisteringVoters, "Users not already registered");
        status = WorkflowStatus.VotingSessionStarted;
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationStarted,WorkflowStatus.VotingSessionStarted);
        emit VotingSessionStarted();
    }
    
    function StopVote() private onlyOwner{
         require(status == WorkflowStatus.VotingSessionStarted, "Vooting has not started yet");
        status = WorkflowStatus.VotingSessionStarted;
        emit WorkflowStatusChange(WorkflowStatus.VotingSessionStarted,WorkflowStatus.VotingSessionEnded);
        emit VotingSessionEnded();
    }
    
    function CountProposals() private {
        // count each proposal
        emit WorkflowStatusChange(WorkflowStatus.VotingSessionStarted,WorkflowStatus.VotingSessionEnded);
        emit VotesTallied();
    }
    // --------------------------------------------------------------------------------------------------------------
    
    // Users voting actions
    // --------------------------------------------------------------------------------------------------------------
    function ProposeRecord(address _address, string memory _descriptionProposal) public {
        require(!_Proposers[_address], "This user has already made a proposal");
        _Proposers[_address] = true;
        RequireIsPropositionStarted();
        Voter memory voter = _whitelist[_address];
        RequireUserRegistered(voter);
        
        Proposals.push(Proposal(_descriptionProposal, 0));
        uint proposalId = Proposals.length - 1;
        
        emit ProposalRegistered(proposalId);
    }
    
    function VoteUser(address _address, uint propoalId) public {
        
        Voter memory voter = _whitelist[_address];
        
        RequireIsVoting();
        
        // if already vote no require
        
        RequireUserRegistered(voter);
        
        require(!voter.hasVoted, "This user has already voted");
        
        voter.hasVoted = true;
        Proposals[propoalId].voteCount += 1; 
        emit Voted(_address, propoalId);
    }
    // --------------------------------------------------------------------------------------------------------------
    
    
    // Required Actions
    // --------------------------------------------------------------------------------------------------------------
    function RequireIsPropositionStarted() view private{
        if(status != WorkflowStatus.ProposalsRegistrationStarted) {
           if(status == WorkflowStatus.RegisteringVoters)
            revert("The propostion voting recording is not started");
           else
            revert("The propostion voting recording is ended");
        }
    }
    
    function RequireIsVoting() view private{
         if(status != WorkflowStatus.VotingSessionStarted) {
           if(status == WorkflowStatus.VotingSessionEnded || status == WorkflowStatus.VotesTallied)
            revert("The voting is finished");
           else
            revert("The voting is not started");
        }
    }
    
    
    function RequireUserRegistered(Voter memory voter) pure private {
         
         require(voter.isRegistered, "This user is not registerd");
    }
    // --------------------------------------------------------------------------------------------------------------
    
}
