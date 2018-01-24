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

contract RPI is OwnedContract {
    
    string public constant name = "Rupie";
    string public constant symbol = "RPI";
    uint256 public constant decimals = 18;  // 18 is the most common number of decimal places
    bool private tradeable;
    uint256 private currentSupply;
    mapping(address => uint256) private balances;
    mapping(address => mapping(address=> uint256)) private allowed;
    mapping(address => bool) private lockedAccounts;  
	
	/*
		Incomming Ether
	*/	
    event RecievedEth(address indexed _from, uint256 _value);
	//this is the fallback
	function () payable public {
		RecievedEth(msg.sender, msg.value);		
	}
	
	event TransferedEth(address indexed _to, uint256 _value);
	function FoundationTransfer(address _to, uint256 amtEth, uint256 amtToken) public onlyOwner
	{
		require(this.balance >= amtEth && balances[this] >= amtToken );
		
		if(amtEth >0)
		{
			_to.transfer(amtEth);
			TransferedEth(_to, amtEth);
		}
		
		if(amtToken > 0)
		{
			require(balances[_to] + amtToken > balances[_to]);
			balances[this] -= amtToken;
			balances[_to] += amtToken;
			Transfer(this, _to, amtToken);
		}
		
		
	}	
	/*
		End Incomming Ether
	*/
	
	
	
    function RPI(
		uint256 initialTotalSupply
		) public
    {
  
        uint256 toCreate = initialTotalSupply * (10**decimals);
		balances[this] = toCreate;
		currentSupply = toCreate;
    }
    
	
    event SoldToken(address _buyer, uint256 _value);
    function BuyToken(address _buyer, uint256 _value) public onlyOwner
    {
		require(balances[this] >= _value && balances[_buyer] + _value > balances[_buyer]);
		
        SoldToken( _buyer,  _value);
        balances[this] -= _value;
        balances[_buyer] += _value;
        Transfer(this, _buyer, _value);
    }
    
    function LockAccount(address toLock) public onlyOwner
    {
        lockedAccounts[toLock] = true;
    }
    function UnlockAccount(address toUnlock) public onlyOwner
    {
        delete lockedAccounts[toUnlock];
    }
    
    function SetTradeable(bool t) public onlyOwner
    {
        tradeable = t;
    }
    function IsTradeable() public view returns(bool)
    {
        return tradeable;
    }
    
    
    function totalSupply() constant public returns (uint256)
    {
        return currentSupply;
    }
    function balanceOf(address _owner) constant public returns (uint256 balance)
    {
        return balances[_owner];
    }
    function transfer(address _to, uint256 _value) public notLocked returns (bool success) {
        require(tradeable);
         if (balances[msg.sender] >= _value && _value > 0 && balances[_to] + _value > balances[_to]) {
             Transfer( msg.sender, _to,  _value);
             balances[msg.sender] -= _value;
             balances[_to] += _value;
             return true;
         } else {
             return false;
         }
     }
    function transferFrom(address _from, address _to, uint _value)public notLocked returns (bool success) {
        require(!lockedAccounts[_from] && !lockedAccounts[_to]);
		require(tradeable);
        if (balances[_from] >= _value
            && allowed[_from][msg.sender] >= _value
            && _value > 0
            && balances[_to] + _value > balances[_to]) {
                
            Transfer( _from, _to,  _value);
                
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            balances[_to] += _value;
            return true;
        } else {
            return false;
        }
    }
    
    function approve(address _spender, uint _value) public returns (bool success) {
        Approval(msg.sender,  _spender, _value);
        allowed[msg.sender][_spender] = _value;
        return true;
    }
    function allowance(address _owner, address _spender) constant public returns (uint remaining){
        return allowed[_owner][_spender];
    }
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
   
   modifier notLocked(){
       require (!lockedAccounts[msg.sender]);
       _;
   }
} 

