// SPDX-License-Identifier: GPL-3.0

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

pragma solidity =0.8.0;

contract Voting is Ownable {
    
    mapping(address=> bool) private _whitelist;
    event Whitelisted(address _address);
    
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
    
    WorkflowStatus status;
    
    Proposal[] Proposals;
    
    
    function whitelist(address _address) public onlyOwner {
      require(!_whitelist[_address], "This address is already whitelisted !");
      _whitelist[_address] = true;
      emit Whitelisted(_address);
  }
    
    function voterRegister(address _address)  public {
        require(_whitelist[_address] = true, "This address is not whiteListed");
        emit VoterRegistered(_address);
    }
    
    function StartProposalsRegistration() public onlyOwner{
        // if admin 
        //Proposals = new Proposal[];
        
        emit ProposalsRegistrationStarted();
        emit WorkflowStatusChange(WorkflowStatus.RegisteringVoters,WorkflowStatus.ProposalsRegistrationStarted);
    }
    
    function StopProposalsRegistration() public onlyOwner{
        // if admin 
         emit ProposalsRegistrationEnded();
         emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationStarted,WorkflowStatus.VotingSessionEnded);
    }
    
    function ProposeRecord(address _address, string memory _descriptionProposal) public {
        // une propsition par user ?
        require(_whitelist[_address] = true, "This address is not whiteListed");
        Proposals.push(Proposal(_descriptionProposal, 0));
        uint proposalId = Proposals.length - 1;
        emit ProposalRegistered(proposalId);
    }
    
    
    function SartVote() public onlyOwner{
        status = WorkflowStatus.VotingSessionStarted;
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationStarted,WorkflowStatus.VotingSessionStarted);
        emit VotingSessionStarted();
    }
    
    function StopVote() public onlyOwner{
        status = WorkflowStatus.VotingSessionEnded;
        emit WorkflowStatusChange(WorkflowStatus.VotingSessionStarted,WorkflowStatus.VotingSessionEnded);
        emit VotingSessionEnded();
    }
    
    function VoteUser(address _address, uint propoalId) public {
        // if already vote no require
        require(_whitelist[_address] = true, "This address is not whiteListed");
        require(status ==  WorkflowStatus.VotingSessionStarted, "Error...");
        emit Voted(_address, propoalId);
    }
    
    function CountProposal() public onlyOwner {
        // count each proposal
        emit WorkflowStatusChange(WorkflowStatus.VotingSessionStarted,WorkflowStatus.VotingSessionEnded);
        emit VotesTallied();
    }
    
    
    
}
