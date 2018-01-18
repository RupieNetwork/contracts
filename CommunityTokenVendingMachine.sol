pragma solidity ^0.4.18;
import "./EtherealFoundationOwned.sol";
contract ERC20Basic {
  function allowance(address _owner, address _spender) constant public returns (uint256 remaining);
  
  function transfer(address to, uint256 value) public returns (bool);
  function transferFrom(address _from, address _to, uint _value) public returns (bool success);
}

contract CommunityTokenVendingMachine is EtherealFoundationOwned{	

	mapping(address=>uint256) Balances;
	mapping(address=>bool) AuthorizedGame;	
	
	uint256 EthereumToCommunityTokenConversionRate;//tokens per ether
	mapping(address=>bool) private AuthorizedExternalTokens;
	mapping(address=>uint256) private ExternalTokenExchangeRates;//suggest update every few hours/day
	
	function balanceOf(address addr) public view returns(uint256){
		return Balances[addr];
	}
	
	event GemPackBought(address _to, bytes32 packType, uint256 totalGems);
	function BuyGemPack(address _to, bytes32 packType, uint256 totalGems)public onlyOwner{
		
		require(Balances[_to] + totalGems > Balances[_to]);
		
		Balances[_to] += totalGems;
		
		GemPackBought( _to, packType, totalGems);
	}
	
	event GameAuthorized(address gameContract);
	function AddAuthorizedGame(address gameContract) public onlyOwner{
		AuthorizedGame[gameContract] = true;
		GameAuthorized(gameContract);
	}
	event GameRemoved(address gameContract);
	function RemoveAuthorizedGame(address gameContract) public onlyOwner{
		delete(AuthorizedGame[gameContract]);
		GameRemoved(gameContract);
	}
	
	event TokensCredited(address funder, uint256 amt);
	function CreditTokens(address funder, uint256 amt) public onlyOwner{
		require(Balances[funder] + amt > Balances[funder]);
		
		Balances[funder] += amt;
		TokensCredited(funder, amt);
	}	
	
	event Transfered(address _from, address _to, uint256 communityTokenAmt, uint256 timestamp); 
	function Transfer(address _from, address _to, uint256 communityTokenAmt) public{
		
		require((AuthorizedGame[msg.sender] || IsOwner(msg.sender)) && Balances[_from] >= communityTokenAmt);
		
		//check for overflow
		require(Balances[_to] + communityTokenAmt > Balances[_to]);
		
		Balances[_from] -= communityTokenAmt;
		Balances[_to] += communityTokenAmt;
		Transfered(_from, _to, communityTokenAmt, now);
		
	}
	event PayingOutEth(address indexed _to);
	event PaidOutEth(address indexed _to, uint256 communityTokenAmtIn, uint256 ethAmtOut);
	function PayoutEth(address _to, uint256 communityTokenAmtIn) public onlyOwner payable{
		require(Balances[_to] >= communityTokenAmtIn);
		
		//burns communityTokenAmtIn
		Balances[_to] -= communityTokenAmtIn;
		
		PayingOutEth(_to);
		_to.transfer(msg.value);
		PaidOutEth(_to, communityTokenAmtIn, msg.value);
		
	}
	
}
