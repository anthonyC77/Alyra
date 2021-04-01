// SPDX-License-Identifier: GPL-3.0

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

pragma solidity =0.8.0;

contract Voting is Ownable {
    
    uint winningProposalId;
    mapping(address=> Voter) private _whitelist;
    Proposal[] Proposals;
    uint[] StatusArray;
    uint NextiStatus = 0;
    WorkflowStatus CurrentStatus = WorkflowStatus.RegisteringVoters;
    uint nbAddress = 0;
    
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
        
        NextiStatus = 1;
        CurrentStatus = WorkflowStatus.RegisteringVoters;
        nbAddress++;
        
        emit VoterRegistered(_address);
        emit WorkflowStatusChange(WorkflowStatus.RegisteringVoters, WorkflowStatus.RegisteringVoters);
    }
    
    function AdminRegisterProsalsStart() public onlyOwner{
        require(nbAddress > 0, "You can't start proposals registration, no adresses are registered");
        AdminActions(WorkflowStatus.ProposalsRegistrationStarted);
    }
    
    function AdminRegisterProsalsStop() public onlyOwner{
        require(Proposals.length > 0, "You can't stop proposals registration, no propositions are registered");
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
    
    function AdminActions(WorkflowStatus _status) private {
        
        // we convert enum in uint to increment it at the end of this call to have the next awaited status for the next call
        uint istatus = uint(_status);
        
         // if it's more than 5 it's after the last WorkflowStatus
        if(istatus > 5)
            revert("There is not further step after the vote is tallied");
            
        // we test if the next event action awaited is the good one if not we throw an error
        if(istatus != NextiStatus)
            revert(ErrorStatus());
          
        if(_status == WorkflowStatus.ProposalsRegistrationStarted) 
            emit ProposalsRegistrationStarted();
        else if(_status == WorkflowStatus.ProposalsRegistrationEnded)
            emit ProposalsRegistrationEnded();
        else if(_status == WorkflowStatus.VotingSessionStarted)
            emit VotingSessionStarted();
        else if(_status == WorkflowStatus.VotingSessionEnded)
            emit VotingSessionEnded();
         else if(_status == WorkflowStatus.VotesTallied)
             CountProposals();
           
        emit WorkflowStatusChange(CurrentStatus,_status);
        NextiStatus++;
        CurrentStatus = _status;
    }
    
    function ErrorStatus() private view returns(string memory){
        string memory nextStep = "The next awaited step is ";
        string memory statusAwaited = "";
        if(NextiStatus == 1)
            statusAwaited = "the proposal registration starting";
        else if(NextiStatus == 2)
            statusAwaited = "the proposal registration ending"; 
        else if(NextiStatus == 3)
            statusAwaited = "the vote starting"; 
        else if(NextiStatus == 4)
            statusAwaited = "the vote ending"; 
        else if(NextiStatus == 5)
            statusAwaited = "the vote counting"; 
        
        return string(abi.encodePacked(nextStep,statusAwaited)); 
    }
    
    function CountProposals() private {
        
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
        // if zero votes ?
        emit VotesTallied(Proposals[proposalIdWInner].description, maxCount);
    }
    // --------------------------------------------------------------------------------------------------------------
    
    // Users voting actions
    // --------------------------------------------------------------------------------------------------------------
    function ProposeRecord(address _address, string memory _descriptionProposal) public {
        RequireIsPropositionStarted();
        Voter memory voter = _whitelist[_address];
        RequireUserRegistered(voter);
       
        Proposals.push(Proposal(_descriptionProposal, 0));
        uint proposalId = Proposals.length - 1;
        
        emit ProposalRegistered(proposalId);
    }
    
    function VoteUser(address _address, uint proposalId) public {
        RequireIsVoting();
        Voter memory voter = _whitelist[_address];
        RequireUserRegistered(voter);
        uint lenProposals = Proposals.length;
        require(proposalId < lenProposals, "This proposition doesn't exist");
        require(!voter.hasVoted, "This user has already voted");
        
        _whitelist[_address].hasVoted = true;
        Proposals[proposalId].voteCount += 1; 
        emit Voted(_address, proposalId);
    }
    // --------------------------------------------------------------------------------------------------------------
    
    
    // Required Actions
    // --------------------------------------------------------------------------------------------------------------
    function RequireIsPropositionStarted() view private{
        if(CurrentStatus != WorkflowStatus.ProposalsRegistrationStarted) {
           if(CurrentStatus == WorkflowStatus.RegisteringVoters)
            revert("The propostion recording is not started");
           else
            revert("The proposition recording is ended");
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
         
         require(voter.isRegistered, "This address is not registered");
    }
    // --------------------------------------------------------------------------------------------------------------
    
}
