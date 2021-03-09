// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.11;

contract Random{
    uint private nonce  = 0;
    function random() view public returns(uint){
        return uint(keccak256(abi.encodePacked(
            block.timestamp,
            msg.sender,
            nonce)));
    }
}
