pragma solidity ^0.4.18;

contract EtherealFoundationOwned {
	address private Owner;
    
	function IsOwner(address addr) view public returns(bool)
	{
	    return Owner == addr;
	}
	
	function TransferOwner(address newOwner) public onlyOwner
	{
	    Owner = newOwner;
	}
	
	function EtherealFoundationOwned() public
	{
	    Owner = msg.sender;
	}
	
	function Terminate() public onlyOwner
	{
	    selfdestruct(Owner);
	}
	
	modifier onlyOwner(){
        require(msg.sender == Owner);
        _;
    }
}