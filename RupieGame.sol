pragma solidity ^0.4.18;
import "./EtherealFoundationOwned.sol";
import "./CommunityTokenVendingMachine.sol";

contract RupieGame is EtherealFoundationOwned{	
	//enum
	enum MilestoneStatuses{ Closed, Open, InReview, Funded, Rejected, Completed }
	enum FeatureStatuses{Closed, Open, InReview, Funded, Rejected, Completed}
	enum TaskStatuses{ Closed, Open, InReview, Completed, Deferred, Rejected }
	
	//structs	
	struct Task{
		bytes32 TaskKey;		
		string Name;
		string Url;
		address TaskCreator;
		bytes32 TaskCategory;
		TaskStatuses TaskStatus;
	}
	struct Milestone{
		bytes32 MilestoneKey;
		string Name;
		string Url;
		uint256 TotalFunds;
		MilestoneStatuses MilestoneStatus;
	}
	struct Feature{
		bytes32 FeatureKey;
		string Name;
		string Url;
		uint256 TotalFunds;
		address FeatureCreator;
		bytes32 FeatureCategory;
		FeatureStatuses FeatureStatus;
	}
	
	//Properties
	string private _name ;
	string private _url;
	address private _gameCreator;	
	
	mapping(bytes32=>Task) Tasks;
	bytes32[] TaskKeys;
	
	mapping(bytes32=>Milestone) Milestones;
	bytes32[] MilestoneKeys;
	
	mapping(bytes32=>Feature) Features;
	bytes32[] FeatureKeys;
	
	mapping(bytes32=>mapping(address=>uint256)) MilestoneFunds;//milestoneKey => funderAddress => funds
	mapping(bytes32=>mapping(address=>uint256)) FeatureFunds;//featureKey => funderAddress => funds
	mapping(bytes32=>bytes32) AssignedTasks; //taskKey => milestoneKey
	mapping(bytes32=>bytes32) AssignedFeatures; //featureKey => milestoneKey
	
	uint16 private _currentMilestoneNumber;
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
	event MilestoneCreated(string title, bytes32 indexed milestoneKey);
	event MilestoneStatusChanged(bytes32 indexed milestoneKey, MilestoneStatuses newMilestoneStatus);
	
	event FeatureCreated(bytes32 indexed featureKey);
	event FeatureStatusChanged(bytes32 indexed featureKey, FeatureStatuses newFeatureStatus);
	
	event TaskCreated(bytes32 taskKey, string url);
	event TaskAttachedToMilestone(bytes32 taskKey, bytes32 milestoneKey);
	event TaskAttachedToFeature(bytes32 taskKey, bytes32 featureKey);
	event TaskStatusChanged(bytes32 indexed taskKey, TaskStatuses newTaskStatus);
	
	event NameUpdated(string name);
	event UrlUpdated(string url);
	event CreatorTransfered(address newCreator);
	
	event FeatureFunded(address funder, bytes32 featureKey, uint256 communityTokenAmt);
	event MilestoneFunded(address funder, bytes32 milestoneKey, uint256 communityTokenAmt);
	
	event FeatureRefunded(address  funder, bytes32 featureKey, uint256 communityTokenAmt);
	event MilestoneRefunded(address  funder, bytes32 milestoneKey, uint256 communityTokenAmt);
	
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

	function GetMilestoneContribution(uint16 milestoneNumber, address funder) public view returns(uint256){
	    return MilestoneFunds[MilestoneNumberToKey(milestoneNumber)][funder];
	
	}
	function GetFunctionContribution(uint16 featureNumber, address funder) public view returns (uint256){
	    return FeatureFunds[FeatureNumberToKey(featureNumber)][funder];
	}
	function GetMilestoneByNumber(uint16 milestoneNumber) public view returns(string Name, string Url, bytes32 MilestoneKey, uint256 TotalFunds, MilestoneStatuses MilestoneStatus) {
    	 return MilestoneToView(Milestones[MilestoneNumberToKey(milestoneNumber)]);
	}
	function GetMilestoneByKey(bytes32 milestoneKey) public view returns(string Name, string Url, bytes32 MilestoneKey, uint256 TotalFunds, MilestoneStatuses MilestoneStatus){
	    return MilestoneToView(Milestones[milestoneKey]);
	}
	
	function GetTaskByKey(bytes32 taskKey) public view returns(string Name, string Url, bytes32 TaskKey,  address TaskCreator, bytes32 AttachedToMilestone, TaskStatuses TaskStatus){
	    return TaskToView( Tasks[taskKey]);
	}
	function GetTaskByNumber(uint16 taskNumber) public view returns(string Name, string Url, bytes32 TaskKey, address TaskCreator, bytes32 AttachedToMilestone, TaskStatuses TaskStatus){
	    return TaskToView(Tasks[TaskNumberToKey(taskNumber)]);
	}
	
	
	function GetFeatureByKey(bytes32 _featureKey) public view returns(string Name, string Url, bytes32 featureKey, uint256 TotalFunds, address FeatureCreator, bytes32 AttachedToMilestone, FeatureStatuses FeatureStatus){
	    return FeatureToView( Features[_featureKey]);
	}
	function GetFeatureByNumber(uint16 featureNumber) public view returns(string Name, string Url, bytes32 featureKey, uint256 TotalFunds, address FeatureCreator, bytes32 AttachedToMilestone, FeatureStatuses FeatureStatus){
	    return FeatureToView(Features[FeatureNumberToKey(featureNumber)]);
	}
	/////////////////////////////////////
	
	//HELPERS
	function MilestoneNumberToKey(uint16 milestoneNumber) internal view returns(bytes32){
	    return MilestoneKeys[milestoneNumber-1];
	}
	function MilestoneToView(Milestone milestone) internal pure returns(string Name, string Url, bytes32 MilestoneKey, uint256 TotalFunds, MilestoneStatuses MilestoneStatus){
	    return (milestone.Name, milestone.Url, milestone.MilestoneKey, milestone.TotalFunds,milestone.MilestoneStatus);
	
	}
	
	function TaskNumberToKey(uint16 taskNumber)internal view returns(bytes32){
	    return TaskKeys[taskNumber-1];
	}
	function TaskToView(Task task) internal view returns(string Name, string Url, bytes32 TaskKey, address TaskCreator, bytes32 AttachedToMilestone, TaskStatuses TaskStatus){
	    return (task.Name, task.Url, task.TaskKey, task.TaskCreator, AssignedTasks[task.TaskKey], task.TaskStatus);
	}
	
	function FeatureNumberToKey(uint16 featureNumber)internal view returns(bytes32){
	    return FeatureKeys[featureNumber-1];
	}
	function FeatureToView(Feature feature) internal view returns(string Name, string Url, bytes32 FeatureKey, uint256 TotalFunds, address FeatureCreator, bytes32 AttachedToMilestone, FeatureStatuses FeatureStatus){
	    return (feature.Name, feature.Url, feature.FeatureKey, feature.TotalFunds, feature.FeatureCreator, AssignedFeatures[feature.FeatureKey], feature.FeatureStatus);
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
		bytes32 milestoneKey = keccak256(now,title,url);
		
		Milestones[milestoneKey] = Milestone(milestoneKey, title, url,0, MilestoneStatuses.Closed);
		MilestoneKeys.push(milestoneKey);
		
		MilestoneCreated(title, milestoneKey);
	}
	
	function SetMilestoneStatus(uint16 milestoneNumber, MilestoneStatuses newMilestoneStatus) public onlyOwner{
		Milestones[MilestoneNumberToKey(milestoneNumber)].MilestoneStatus = newMilestoneStatus;
		if(newMilestoneStatus == MilestoneStatuses.Funded){
	    	CommunityTokenVendingMachine(_vendingMachineContractAddress).Transfer(this, _gameCreator, Milestones[MilestoneNumberToKey(milestoneNumber)].TotalFunds);
		}
		MilestoneStatusChanged(MilestoneNumberToKey(milestoneNumber), newMilestoneStatus);
	}
	
	function SetTaskStatus(uint16 taskNumber, TaskStatuses newTaskStatus) public onlyOwner{
		Tasks[TaskNumberToKey(taskNumber)].TaskStatus = newTaskStatus;
		TaskStatusChanged(TaskNumberToKey(taskNumber), newTaskStatus);
	}
	
	function AttachTaskToMilestone(uint16 taskNumber, uint16 milestoneNumber) public onlyOwner {
		AssignedTasks[TaskNumberToKey(taskNumber)] = MilestoneNumberToKey(milestoneNumber);
	}	
	
	function SetCurrentMilestone(uint16 milestoneNumber) public onlyOwner{
		_currentMilestoneNumber = milestoneNumber;
	}
	
	function SetFeatureStatus(uint16 featureNumber, FeatureStatuses newFeatureStatus) public onlyOwner{
		Features[FeatureNumberToKey(featureNumber)].FeatureStatus = newFeatureStatus;
		if(newFeatureStatus == FeatureStatuses.Funded){
	    	CommunityTokenVendingMachine(_vendingMachineContractAddress).Transfer(this, _gameCreator, Features[FeatureNumberToKey(featureNumber)].TotalFunds);
		}
		FeatureStatusChanged(FeatureNumberToKey(featureNumber), newFeatureStatus);
	}
	function AttachFeatureToMilestone(uint16 featureNumber) public onlyOwner{
		AssignedFeatures[FeatureNumberToKey(featureNumber)] = FeatureNumberToKey(featureNumber);
	}	
	///////////////////////////
	
	/////COMMUNITY METHODS/////
	function CreateTask(string name, string url) public {
		
		//TODO, charge for this
		bytes32 taskKey = keccak256(now,name,url);
		
		Tasks[taskKey] = Task(taskKey,	name, url, msg.sender,0,TaskStatuses.Closed);
		
		TaskKeys.push(taskKey);
		TaskCreated(taskKey, url);
	}
	function CreateFeature(string name, string url, bytes32 featureCategory) public {
		
		//TODO, charge for this
		bytes32 featureKey = keccak256(now,name,url);
		
		Features[featureKey] = Feature(featureKey, name, url, 0,msg.sender,featureCategory,FeatureStatuses.Closed);
		
		FeatureKeys.push(featureKey);
		FeatureCreated(featureKey);
	}
	
	function FundMilestone(uint16 milestoneNumber, uint256 communityTokenAmt) public{
	    require(Milestones[MilestoneNumberToKey(milestoneNumber)].MilestoneStatus == MilestoneStatuses.Open);
		CommunityTokenVendingMachine(_vendingMachineContractAddress).Transfer(msg.sender, this, communityTokenAmt);
		
		//if it gets here, it was OK
		MilestoneFunds[MilestoneNumberToKey(milestoneNumber)][msg.sender] +=  communityTokenAmt;
		Milestones[MilestoneNumberToKey(milestoneNumber)].TotalFunds += communityTokenAmt;
		MilestoneFunded(msg.sender, MilestoneNumberToKey(milestoneNumber), communityTokenAmt);
	}
	function FundFeature(uint16 featureNumber, uint256 communityTokenAmt) public{
	    require(Features[FeatureNumberToKey(featureNumber)].FeatureStatus == FeatureStatuses.Open);
	    
		CommunityTokenVendingMachine(_vendingMachineContractAddress).Transfer(msg.sender, this, communityTokenAmt);
		
		//if it gets here, we are good
		FeatureFunds[FeatureNumberToKey(featureNumber)][msg.sender] +=  communityTokenAmt;
		Features[FeatureNumberToKey(featureNumber)].TotalFunds += communityTokenAmt;
		
		FeatureFunded(msg.sender, FeatureNumberToKey(featureNumber), communityTokenAmt);
	}
	function RemoveFundsFromMilestone(uint16 milestoneNumber) public{
		//must be rejected and have a balance
		require(Milestones[MilestoneNumberToKey(milestoneNumber)].MilestoneStatus == MilestoneStatuses.Rejected && MilestoneFunds[MilestoneNumberToKey(milestoneNumber)][msg.sender] > 0);
		
		CommunityTokenVendingMachine(_vendingMachineContractAddress).Transfer(this, msg.sender, MilestoneFunds[MilestoneNumberToKey(milestoneNumber)][msg.sender]);
		Milestones[MilestoneNumberToKey(milestoneNumber)].TotalFunds -= MilestoneFunds[MilestoneNumberToKey(milestoneNumber)][msg.sender];
		
		MilestoneRefunded(msg.sender, MilestoneNumberToKey(milestoneNumber), MilestoneFunds[MilestoneNumberToKey(milestoneNumber)][msg.sender]);
		MilestoneFunds[MilestoneNumberToKey(milestoneNumber)][msg.sender] = 0;
		
		
	}
	function RemoveFundsFromFeature(uint16 featureNumber)public{
		//must be rejected
		require(Features[FeatureNumberToKey(featureNumber)].FeatureStatus == FeatureStatuses.Rejected && FeatureFunds[FeatureNumberToKey(featureNumber)][msg.sender] > 0);
		uint256 toRefund = FeatureFunds[FeatureNumberToKey(featureNumber)][msg.sender];
	
		CommunityTokenVendingMachine(_vendingMachineContractAddress).Transfer(this, msg.sender, toRefund);
		Features[FeatureNumberToKey(featureNumber)].TotalFunds -=  toRefund;
		FeatureRefunded(msg.sender, FeatureNumberToKey(featureNumber),  toRefund);
		FeatureFunds[FeatureNumberToKey(featureNumber)][msg.sender] = 0;
	}	
	///////////////////////////
	
	
	//fallback
    event RecievedEth(address indexed _from, uint256 _value);
	function () payable public {
		//these funds will automatically be assigned to the current milestone
		RecievedEth(msg.sender, msg.value);
	}
	
	
}