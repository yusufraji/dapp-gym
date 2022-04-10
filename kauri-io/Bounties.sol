pragma solidity ^0.5.0;

contract Bounties {

    /*
    * Enums
    */
    enum BountyStatus { CREATED, ACCEPTED, CANCELLED }

    /*
    * Storage
    */
    Bounty[] public bounties;

    mapping(uint=>Fulfillment[]) fulfillments;
    
    /*
    * Structs
    */
    struct Bounty {
        address payable issuer;
        uint deadline;
        string data;
        BountyStatus status;
        uint amount;
    }

    struct Fulfillment {
        address payable fulfiller;
        string data;
        bool accepted;

    }

    /**
    * @dev Constructor
    */
    constructor() public {}

    /**
    * @dev issueBounty(): instantiates a new bounty
    * @param _deadline the unix timestamp after which fulfillments will no longer be accepted
    * @param _data the requirements of the bounty
    */
    function issueBounty(
        string memory _data,
        uint64 _deadline
    )

    public payable 
    hasValue() 
    validateDeadline(_deadline) 
    returns (uint)
    {
        bounties.push(Bounty(msg.sender, _deadline, _data, BountyStatus.CREATED, msg.value));
        emit BountyIssued(bounties.length - 1, msg.sender, msg.value, _data);
        return (bounties.length - 1);
    }

    /**
    * @dev fulfillBounty: store a fulfillment record attached to a given bounty
    * @param _bountyId the index of the bounty to be fulfilled
    * @param _data the ipfs hash containing evidence of the fulfillment
    */
    function fulfillBounty(uint _bountyId, string memory _data)
    public
    bountyExists(_bountyId)
    hasStatus(_bountyId, BountyStatus.CREATED)
    notIssuer(_bountyId)
    isBeforeDeadline(_bountyId)
    {
        fulfillments[_bountyId].push(Fulfillment(msg.sender, _data, false));
        emit BountyFulfilled(_bountyId, msg.sender, (fulfillments[_bountyId].length - 1), _data);
    }

    /**
    * @dev acceptFulfillment: accept a given fulfillment if the record exists
    * @param _bountyId the index of the bounty to be fulfilled
    * @param _fulfillmentId the index of the fulfillment being accepted
    */
    function acceptFulfillment(uint _bountyId, uint _fulfillmentId)
    public
    bountyExists(_bountyId)
    onlyIssuer(_bountyId)
    hasStatus(_bountyId, BountyStatus.CREATED)
    fulfillmentExists(_bountyId, _fulfillmentId)
    fulfillmentNotYetAccepted(_bountyId, _fulfillmentId)
    {
        fulfillments[_bountyId][_fulfillmentId].accepted = true;
        bounties[_bountyId].status = BountyStatus.ACCEPTED;
        fulfillments[_bountyId][_fulfillmentId].fulfiller.transfer(bounties[_bountyId].amount);
        emit FulfillmentAccepted(_bountyId, bounties[_bountyId].issuer, fulfillments[_bountyId][_fulfillmentId].fulfiller, _fulfillmentId, bounties[_bountyId].amount);
    }

    /**
    * @dev cancelBounty: 
    * @param _bountyId the index of the bounty to cancel
    */
    function cancelBounty(uint _bountyId)
    public
    bountyExists(_bountyId)
    onlyIssuer(_bountyId)
    hasStatus(_bountyId, BountyStatus.CREATED)
    {
        bounties[_bountyId].status = BountyStatus.CANCELLED;
        bounties[_bountyId].issuer.transfer(bounties[_bountyId].amount);
        emit BountyCancelled(_bountyId, msg.sender, bounties[_bountyId].amount);
    }

    /**
    * Modifiers
    */
    modifier validateDeadline(uint _newDeadline) {
        require(_newDeadline > now);
        _;
    }

    modifier hasValue() {
        require(msg.value > 0);
        _;
    }

    modifier bountyExists(uint _bountyId) {
        require(_bountyId < bounties.length);
        _;
    }

    modifier hasStatus(uint _bountyId, BountyStatus _dersiredStatus) {
        require(bounties[_bountyId].status == _dersiredStatus);
        _;
    }

    modifier notIssuer(uint _bountyId) {
        require(msg.sender != bounties[_bountyId].issuer);
        _;
    }

    modifier onlyIssuer(uint _bountyId) {
        require(msg.sender == bounties[_bountyId].issuer);
        _;
    }


    modifier isBeforeDeadline(uint _bountyId) {
        require(now < bounties[_bountyId].deadline);
        _;
    }

    modifier fulfillmentExists(uint _bountyId, uint _fulfillmentId) {
        require(_fulfillmentId < fulfillments[_bountyId].length);
        _;
    }

    modifier fulfillmentNotYetAccepted(uint _bountyId, uint _fulfillmentId) {
        require(fulfillments[_bountyId][_fulfillmentId].accepted == false);
        _;
    }

    /*
    * Events
    */
    event BountyIssued(uint bounty_id, address issuer, uint amount, string data);
    event BountyFulfilled(uint bounty_id, address fulfiller, uint fulfillment_id, string data);
    event FulfillmentAccepted(uint bounty_id, address issuer, address fulfiller, uint indexed fulfillment_id, uint amount);
    event BountyCancelled(uint bounty_id, address issuer, uint amount);


}




