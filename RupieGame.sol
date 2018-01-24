pragma solidity ^0.4.18;

contract OwnedContract {
	address private Owner;    
	function IsOwner(address addr) view public returns(bool)
	{
	    return Owner == addr;
	}	
	function TransferOwner(address newOwner) public onlyOwner
	{
	    Owner = newOwner;
	}	
	function OwnedContract() public
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

contract ERC20Basic {
	function balanceOf(address _owner) public constant returns (uint256 balance);
	function transfer(address to, uint256 value) public returns (bool);
}


contract RupieGame is OwnedContract{	
	
	//Properties
	string private _name ;
	string private _url;
	address private _gameCreator;	
	address private _rpiContractAddress;
	
	bytes32 private _currentMilestoneId;
	mapping(bytes32=>bool) private _milestoneComplete;
	
	uint256 private _gemsBalance;
	
	//EVENTS
	event Funded(uint256 funds, bytes32 fundId);
	event Defunded(uint256 fundsRemoved, bytes32 defundId);
	event Paid(uint256 gemsSpent, uint256 erc20Paid, bytes32 payId);
	
	function RupieGame(string name, string url, address gameCreator, address rpiContractAddress, bytes32 initialMilestoneId) public{
		_name = name;
		_url = url;
		_gameCreator = gameCreator;
		_rpiContractAddress = rpiContractAddress;
		_currentMilestoneId = initialMilestoneId;
	}
	
	function about() public view returns(
	string name, string url, address gameCreator, address rpiContractAddress, bytes32 currentMilestoneId, uint256 gemsBalance){
		return (_name, _url, _gameCreator, _rpiContractAddress, _currentMilestoneId, _gemsBalance);
	}
	function gemsBalance() public view returns(uint256){
		return _gemsBalance;
	}
	
	function fund(uint256 newFunds, bytes32 fundId) public onlyOwner{
		require(newFunds + _gemsBalance > _gemsBalance);//overflow check
		_gemsBalance += newFunds;	
		Funded(newFunds, fundId);	
	}
	
	function defund(uint256 fundsToRemove, bytes32 defundId) public onlyOwner{
		require(_gemsBalance - fundsToRemove >= 0);
		_gemsBalance -= fundsToRemove;	
		Defunded(fundsToRemove, defundId);	
	}
	
	function payout(uint256 erc20ToSend, uint256 gemsToSpend, bytes32 nextMilestone, bytes32 payId) public onlyOwner{
		require(_gemsBalance >= gemsToSpend);
		
		_milestoneComplete[_currentMilestoneId] = true;
		_currentMilestoneId = nextMilestone;
		_gemsBalance -= gemsToSpend;
		
		if(erc20ToSend > 0){
			ERC20Basic erc20 = ERC20Basic(_rpiContractAddress);
			require(erc20.transfer(_gameCreator, erc20ToSend));
		}
		
		Paid(gemsToSpend, erc20ToSend, payId);
	}
	
	
}
