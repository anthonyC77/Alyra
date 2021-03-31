// SPDX-License-Identifier: GPL-3.0

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

pragma solidity =0.8.0;

contract Voting is Ownable {
    
    uint winningProposalId;
    mapping(address=> Voter) private _whitelist;
    mapping(address=> bool) private _Proposers;
    Proposal[] Proposals;
    uint[] StatusArray;
    uint NextiSTatus = 0;
    WorkflowStatus CurrentStatus = WorkflowStatus.RegisteringVoters;
    
    event VoterRegistered(address voterAddress);
    event ProposalsRegistrationStarted();
    event ProposalsRegistrationEnded();
    event ProposalRegistered(uint proposalId);
    event VotingSessionStarted();
    event VotingSessionEnded();
    event Voted (address voter, uint proposalId);
    event VotesTallied(string proposalWinning, uint nbVoices);
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
        RegisteringVoters,              // 0
        ProposalsRegistrationStarted,   // 1
        ProposalsRegistrationEnded,     // 2
        VotingSessionStarted,           // 3
        VotingSessionEnded,             // 4
        VotesTallied                    // 5
    }
    
    // Admin actions
    // --------------------------------------------------------------------------------------------------------------
    function AdminVoterRegister(address _address) public onlyOwner {
        require(CurrentStatus ==  WorkflowStatus.RegisteringVoters, "The voting registering is ended");
        require(!_whitelist[_address].isRegistered, "User already registred");
        
        Voter memory voter = Voter(true, false, 0);
        _whitelist[_address] = voter;
        _Proposers[_address] = false;
        
        NextiSTatus = 1;
        CurrentStatus = WorkflowStatus.RegisteringVoters;
        
        emit VoterRegistered(_address);
        emit WorkflowStatusChange(WorkflowStatus.RegisteringVoters, WorkflowStatus.RegisteringVoters);
    }
    
    function AdminRegisterProsalsStart() public onlyOwner{
        AdminActions(WorkflowStatus.ProposalsRegistrationStarted);
    }
    
    function AdminRegisterProsalsStop() public onlyOwner{
        AdminActions(WorkflowStatus.ProposalsRegistrationEnded);
    }
    
    function AdminStartVoting() public onlyOwner{
        AdminActions(WorkflowStatus.VotingSessionStarted);
    }
    
    function AdminStopVoting() public onlyOwner{
        AdminActions(WorkflowStatus.VotingSessionEnded);
    }
    
    function AdminAllied() public onlyOwner{
        AdminActions(WorkflowStatus.VotesTallied);
    }
    
    
    function  AdminActions(WorkflowStatus _status) private {
        
        // we convert enum in uint to increment it athe end of this call to have the next awaited status for the next call
        uint istatus = uint(_status);
        
        // we test if the next event action awaited is the good one if not we throw an error
        // if it's more than 5 it's after the last WorkflowStatus
        if(istatus != NextiSTatus || istatus > 5)
            revert("The next action is not the awaited one");
          
        if(_status == WorkflowStatus.ProposalsRegistrationStarted) 
            RegisterProposalsStart();
        else if(_status == WorkflowStatus.ProposalsRegistrationEnded)
            RegisterProposalsStop();
        else if(_status == WorkflowStatus.VotingSessionStarted)
            VotingStart();
        else if(_status == WorkflowStatus.VotingSessionEnded)
            VotingStop();
         else if(_status == WorkflowStatus.VotesTallied)
             CountProposals();
         
           
        emit WorkflowStatusChange(CurrentStatus,_status);
        NextiSTatus++;
        CurrentStatus = _status;
    }
    
    function RegisterProposalsStart() private{
        require(CurrentStatus ==  WorkflowStatus.RegisteringVoters,"Users not registered yet");
        emit ProposalsRegistrationStarted();
    }
    
    function RegisterProposalsStop() private{
        require(CurrentStatus ==  WorkflowStatus.ProposalsRegistrationStarted,"Proposal session not started");
        emit ProposalsRegistrationEnded();
    }
    
    function VotingStart() private{
        require(CurrentStatus ==  WorkflowStatus.ProposalsRegistrationEnded,"Proposal session not ended");
            emit VotingSessionStarted();
    }
    
    function VotingStop() private{
        require(CurrentStatus ==  WorkflowStatus.VotingSessionStarted,"voting session not started");
            emit VotingSessionEnded();
    }
    
    function CountProposals() private {
        
        require(CurrentStatus ==  WorkflowStatus.VotingSessionEnded,"voting session not ended");
        
        uint maxCount = 0;
        uint proposalIdWInner = 0;
        
        uint proposalId;
        
        for(proposalId =0;proposalId< Proposals.length;proposalId++){
            uint countProposalID = Proposals[proposalId].voteCount;
            if (countProposalID > maxCount){
                maxCount = countProposalID;
                proposalIdWInner = proposalId;
            }
        }
        
        
        emit VotesTallied(Proposals[proposalIdWInner].description, maxCount);
    }
    // --------------------------------------------------------------------------------------------------------------
    
    // Users voting actions
    // --------------------------------------------------------------------------------------------------------------
    function ProposeRecord(address _address, string memory _descriptionProposal) public {
        RequireIsPropositionStarted();
        Voter memory voter = _whitelist[_address];
        RequireUserRegistered(voter);
        require(!_Proposers[_address], "This user has already made a proposal");
        _Proposers[_address] = true;
       
        Proposals.push(Proposal(_descriptionProposal, 0));
        uint proposalId = Proposals.length - 1;
        
        emit ProposalRegistered(proposalId);
    }
    
    function VoteUser(address _address, uint propoalId) public {
        RequireIsVoting();
        // if already vote no require
        Voter memory voter = _whitelist[_address];
        RequireUserRegistered(voter);
        
        require(!voter.hasVoted, "This user has already voted");
        
        _whitelist[_address].hasVoted = true;
        Proposals[propoalId].voteCount += 1; 
        
        emit Voted(_address, propoalId);
    }
    // --------------------------------------------------------------------------------------------------------------
    
    
    // Required Actions
    // --------------------------------------------------------------------------------------------------------------
    function RequireIsPropositionStarted() view private{
        if(CurrentStatus != WorkflowStatus.ProposalsRegistrationStarted) {
           if(CurrentStatus == WorkflowStatus.RegisteringVoters)
            revert("The propostion voting recording is not started");
           else
            revert("The propostion voting recording is ended");
        }
    }
    
    function RequireIsVoting() view private{
         if(CurrentStatus != WorkflowStatus.VotingSessionStarted) {
           if(CurrentStatus == WorkflowStatus.VotingSessionEnded || CurrentStatus == WorkflowStatus.VotesTallied)
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
