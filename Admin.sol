// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

contract Admin{
    
    mapping(address=> bool) whitelist;
    event Whitelisted(address);
    event Blacklisted(address);
    
    
    function isWhitelisted(address _address) public {
        whitelist[_address] = true;
    }
    
    function isBlacklisted(address _address)  public{
        whitelist[_address] = false;
    }
    
    modifier costs(uint price) {
      if (msg.value >= price) {
         _;
      }
   }
    
}
