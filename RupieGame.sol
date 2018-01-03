pragma solidity ^0.4.19;
import "./EtherealFoundationOwned.sol";
import "./CommunityTokenVendingMachine.sol";

contract RupieGame is EtherealFoundationOwned{	
	//enum
	enum Statuses{ Closed, Open, InReview, Funded, Rejected, Completed, Deferred }
	
	//structs	
	struct Task{		
		string Name;
		string Url;
		address TaskCreator;
		bytes32 TaskCategory;
		Statuses TaskStatus;
	}
	struct Milestone{
		string Name;
		string Url;
		uint256 TotalFunds;
		Statuses MilestoneStatus;
	}
	struct Feature{
		string Name;
		string Url;
		uint256 TotalFunds;
		address FeatureCreator;
		bytes32 FeatureCategory;
		Statuses FeatureStatus;
	}
	
	//Properties
	string private _name ;
	string private _url;
	address private _gameCreator;	
	
	Task[] Tasks;
	Milestone[] Milestones;
	Feature[] Features;
	
	mapping(uint16=>mapping(address=>uint256)) MilestoneFunds;//milestoneIdx => funderAddress => funds
	mapping(uint16=>mapping(address=>uint256)) FeatureFunds;//featureIdx => funderAddress => funds
	mapping(uint16=>uint16) AssignedTasks; //taskIdx => milestoneIdx
	mapping(uint16=>uint16) AssignedFeatures; //featureIdx => milestoneIdx
	
	uint16 private _currentMilestoneIndex;
	address private _vendingMachineContractAddress;
	
	//constructor	
	function RupieGame (string name, string url, address creator, address vendingMachineContractAddress ) public{
			//start game with link to pitch
			_name = name;
			_url = url;
			_gameCreator = creator;
			_vendingMachineContractAddress = vendingMachineContractAddress;
	}
	
	//EVENTES
	event MilestoneCreated(string title, uint16 indexed milestoneIdx);
	event MilestoneStatusChanged(uint16 indexed milestoneIdx, Statuses newMilestoneStatus);
	
	event FeatureCreated(uint16 indexed featureIdx);
	event FeatureStatusChanged(uint16 indexed featureIdx, Statuses newFeatureStatus);
	
	event TaskCreated(uint16 taskIdx, string url);
	event TaskAttachedToMilestone(uint16 taskIdx, uint16 milestoneIdx);
	event TaskAttachedToFeature(uint16 taskIdx, uint16 featureIdx);
	event TaskStatusChanged(uint16 indexed taskIdx, Statuses newTaskStatus);
	
	event NameUpdated(string name);
	event UrlUpdated(string url);
	event CreatorTransfered(address newCreator);
	
	event FeatureFunded(address funder, uint16 featureIdx, uint256 communityTokenAmt);
	event MilestoneFunded(address funder, uint16 milestoneIdx, uint256 communityTokenAmt);
	
	event FeatureRefunded(address  funder, uint16 featureIdx, uint256 communityTokenAmt);
	event MilestoneRefunded(address  funder, uint16 milestoneIdx, uint256 communityTokenAmt);
	
	//VIEWS
	function GetName() public view returns(string){
	    return _name;
	
	}
	function GetUrl() public view returns(string){
	    return _url;
	
	}
	function GetTokenVendingMachineAddress() public view returns(address){
	    return _vendingMachineContractAddress;
	
	}
	function GetGameCreator() public view returns(address){
	    return _gameCreator;
	}

	function GetMilestoneContribution(uint16 milestoneIndex, address funder) public view returns(uint256){
	    return MilestoneFunds[milestoneIndex][funder];
	
	}
	function GetFunctionContribution(uint16 featureIndex, address funder) public view returns (uint256){
	    return FeatureFunds[featureIndex][funder];
	}
	function GetMilestoneByNumber(uint16 milestoneIndex) public view returns(string Name, string Url,  uint256 TotalFunds, Statuses MilestoneStatus) {
    	 return MilestoneToView(Milestones[milestoneIndex]);
	}
	
	function GetTaskByNumber(uint16 taskIndex) public view returns(string Name, string Url,  address TaskCreator, uint16 AttachedToMilestone, Statuses TaskStatus){
	    return TaskToView(Tasks[taskIndex], taskIndex);
	}
	
	
	function GetFeatureByNumber(uint16 featureIndex) public view returns(string Name, string Url,  uint256 TotalFunds, address FeatureCreator, uint16 AttachedToMilestone, Statuses FeatureStatus){
	    return FeatureToView(Features[featureIndex], featureIndex);
	}
	/////////////////////////////////////
	
	//HELPERS
	function MilestoneToView(Milestone milestone) internal pure returns(string Name, string Url,  uint256 TotalFunds, Statuses MilestoneStatus){
	    return (milestone.Name, milestone.Url, milestone.TotalFunds,milestone.MilestoneStatus);
	
	}
	
	function TaskToView(Task task, uint16 taskIdx) internal view returns(string Name, string Url,  address TaskCreator, uint16 AttachedToMilestone, Statuses TaskStatus){
	    return (task.Name, task.Url, task.TaskCreator, AssignedTasks[taskIdx], task.TaskStatus);
	}
	
	function FeatureToView(Feature feature, uint16 featureIdx) internal view returns(string Name, string Url, uint256 TotalFunds, address FeatureCreator, uint16 AttachedToMilestone, Statuses FeatureStatus){
	    return (feature.Name, feature.Url,  feature.TotalFunds, feature.FeatureCreator, AssignedFeatures[featureIdx], feature.FeatureStatus);
	}
	//////////
	
	//OWNER METHODS
	function UpdateName(string name) public onlyOwner {
		_name = name;
		NameUpdated(name);
		
	}
	function UpdateUrl(string url) public onlyOwner { 
		_url = url;
		UrlUpdated(url);
	}	
	function TransferCreator(address newCreator) public onlyOwner {
		_gameCreator = newCreator;
		CreatorTransfered(newCreator);
	}
	function CreateMilestone(string title, string url) public onlyOwner{
	    
		Milestones.push(Milestone(title, url,0, Statuses.Closed));
		
		MilestoneCreated(title, uint16(Milestones.length-1));
	}
	
	function SetMilestoneStatus(uint16 milestoneIndex, Statuses newMilestoneStatus) public onlyOwner{
		Milestones[milestoneIndex].MilestoneStatus = newMilestoneStatus;
		if(newMilestoneStatus == Statuses.Funded){
	    	CommunityTokenVendingMachine(_vendingMachineContractAddress).Transfer(this, _gameCreator, Milestones[milestoneIndex].TotalFunds);
		}
		MilestoneStatusChanged(milestoneIndex, newMilestoneStatus);
	}
	
	function SetTaskStatus(uint16 taskIndex, Statuses newTaskStatus) public onlyOwner{
		Tasks[taskIndex].TaskStatus = newTaskStatus;
		TaskStatusChanged(taskIndex, newTaskStatus);
	}
	
	function AttachTaskToMilestone(uint16 taskIndex, uint16 milestoneIndex) public onlyOwner {
		AssignedTasks[taskIndex] = milestoneIndex;
	}	
	
	function SetCurrentMilestone(uint16 milestoneIndex) public onlyOwner{
		_currentMilestoneIndex = milestoneIndex;
	}
	
	function SetFeatureStatus(uint16 featureNumber, Statuses newFeatureStatus) public onlyOwner{
		Features[featureNumber-1].FeatureStatus = newFeatureStatus;
		if(newFeatureStatus == Statuses.Funded){
	    	CommunityTokenVendingMachine(_vendingMachineContractAddress).Transfer(this, _gameCreator, Features[featureNumber-1].TotalFunds);
		}
		FeatureStatusChanged(featureNumber-1, newFeatureStatus);
	}
	function AttachFeatureToMilestone(uint16 featureIndex, uint16 milestoneIndex) public onlyOwner{
		AssignedFeatures[featureIndex] = milestoneIndex;
	}	
	///////////////////////////
	
	/////COMMUNITY METHODS/////
	function CreateTask(string name, string url) public {
		
		//TODO, charge for this
		
		Tasks.push(Task(	name, url, msg.sender,0,Statuses.Closed));
		TaskCreated(uint16(Tasks.length-1), url);
	}
	function CreateFeature(string name, string url, bytes32 featureCategory) public {
		
		//TODO, charge for this
		Features.push(Feature(name, url, 0,msg.sender,featureCategory,Statuses.Closed));
		FeatureCreated(uint16(Features.length-1));
	}
	
	function FundMilestone(uint16 milestoneIndex, uint256 communityTokenAmt) public{
	    require(Milestones[milestoneIndex].MilestoneStatus == Statuses.Open);
		CommunityTokenVendingMachine(_vendingMachineContractAddress).Transfer(msg.sender, this, communityTokenAmt);
		
		//if it gets here, it was OK
		MilestoneFunds[milestoneIndex][msg.sender] +=  communityTokenAmt;
		Milestones[milestoneIndex].TotalFunds += communityTokenAmt;
		MilestoneFunded(msg.sender, milestoneIndex, communityTokenAmt);
	}
	function FundFeature(uint16 featureIndex, uint256 communityTokenAmt) public{
	    require(Features[featureIndex].FeatureStatus == Statuses.Open);
	    
		CommunityTokenVendingMachine(_vendingMachineContractAddress).Transfer(msg.sender, this, communityTokenAmt);
		
		//if it gets here, we are good
		FeatureFunds[featureIndex][msg.sender] +=  communityTokenAmt;
		Features[featureIndex].TotalFunds += communityTokenAmt;
		
		FeatureFunded(msg.sender, featureIndex, communityTokenAmt);
	}
	function RemoveFundsFromMilestone(uint16 milestoneIndex) public{
		//must be rejected and have a balance
		require(Milestones[milestoneIndex].MilestoneStatus == Statuses.Rejected && MilestoneFunds[milestoneIndex][msg.sender] > 0);
		
		CommunityTokenVendingMachine(_vendingMachineContractAddress).Transfer(this, msg.sender, MilestoneFunds[milestoneIndex][msg.sender]);
		Milestones[milestoneIndex].TotalFunds -= MilestoneFunds[milestoneIndex][msg.sender];
		
		MilestoneRefunded(msg.sender, milestoneIndex, MilestoneFunds[milestoneIndex][msg.sender]);
		MilestoneFunds[milestoneIndex][msg.sender] = 0;
		
		
	}
	function RemoveFundsFromFeature(uint16 featureIndex)public{
		//must be rejected
		require(Features[featureIndex].FeatureStatus == Statuses.Rejected && FeatureFunds[featureIndex][msg.sender] > 0);
		uint256 toRefund = FeatureFunds[featureIndex][msg.sender];
	
		CommunityTokenVendingMachine(_vendingMachineContractAddress).Transfer(this, msg.sender, toRefund);
		Features[featureIndex].TotalFunds -=  toRefund;
		FeatureRefunded(msg.sender, featureIndex,  toRefund);
		FeatureFunds[featureIndex][msg.sender] = 0;
	}	
	///////////////////////////
	
	
	//fallback
    event RecievedEth(address indexed _from, uint256 _value);
	function () payable public {
		//these funds will automatically be assigned to the current milestone
		RecievedEth(msg.sender, msg.value);
	}
	
	
}
