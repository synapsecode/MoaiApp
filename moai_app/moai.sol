// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPUSHCommInterface {
    function sendNotification(
        address _channel,
        address _recipient,
        bytes calldata _identity
    ) external;
}

struct Member {
    bool exists;
    uint256 balance;
    bool hasVoted;
}

event MemberAdded(address indexed member);
event VoteCasted(address indexed voter, bool vote);
event FundsSent(address indexed recipient, uint256 amount);
event FundsNotSent(address indexed recipient, uint256 amount);
event Contribution(address indexed member, uint256 amount);
event VotingStarted(
    address indexed initiator,
    address indexed recipient,
    uint256 amount
);
event TargettedPushNotificationSent(address indexed member, string title, string message);
event NotificiationBroadcasted(string title, string message);

contract MoaiContract {
    address public admin;
    uint256 public standardAmount;
    address public pushProtocolContractAddress;

    mapping(address => Member) public members;
    address[] public memberAddresses;


    modifier onlyMembers() {
        require(members[msg.sender].exists, "Not a member");
        _;
    }

    modifier hasNotVoted() {
        require(!members[msg.sender].hasVoted, "Already voted");
        _;
    }

    constructor(uint256 _standardAmount, address _contractAddress) {
        admin = msg.sender;
        standardAmount = _standardAmount;
        pushProtocolContractAddress = _contractAddress;
    }

    function addMember(address _member) external {
        require(!members[_member].exists, "Member already exists");
        members[_member] = Member(true, 0, false);
        memberAddresses.push(_member);
        emit MemberAdded(_member);
    }

    function contribute() external payable onlyMembers {
        require(msg.value == standardAmount, "Invalid contribution amount");
        members[msg.sender].balance += msg.value;
        emit Contribution(msg.sender, msg.value);
    }

    function startVoting(
        address _recipient,
        uint256 _amount
    ) external onlyMembers {
        require(
            _amount <= members[_recipient].balance,
            "Insufficient funds for recipient"
        );
        require(_amount > 0, "Amount must be greater than zero");

        // Reset voting status for all members
        for (uint256 i = 0; i < memberAddresses.length; i++) {
            members[memberAddresses[i]].hasVoted = false;
        }

        emit VotingStarted(msg.sender, _recipient, _amount);
        sendBroadcast('Voting Initiated', string(abi.encodePacked(_recipient, ' wants to withdraw ', _amount, 'ETH')));
    }

    function castVote(bool _vote) external onlyMembers hasNotVoted {
        members[msg.sender].hasVoted = true;
        emit VoteCasted(msg.sender, _vote);
    }

    function initiateTransfer(
        address _recipient,
        uint256 _amount
    ) external  {
        require(_amount > 0, "Amount must be greater than zero");

        uint256 totalVotes = 0;
        uint256 totalMembers = memberAddresses.length;

        // Count the number of "yes" votes
        for (uint256 i = 0; i < totalMembers; i++) {
            if (members[memberAddresses[i]].hasVoted) {
                totalVotes += 1;
            }
        }

        // Check if more than 50% voted "yes"
        require(totalVotes > totalMembers / 2, "Insufficient votes");
        if( totalVotes < totalMembers/2){
            emit FundsNotSent(_recipient, _amount);
            sendTargettedNotification(_recipient, 'Funds Not Transferred', 'You lost the group vote');
        }else{
             // Transfer funds to the recipient
            payable(_recipient).transfer(_amount);
            emit FundsSent(_recipient, _amount);
            sendTargettedNotification(_recipient, 'Funds Transferred', 'You should have recieved your amount');
        }
    }

    // Function to retrieve the contract's balance
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function sendTargettedNotification(
        address receiver,
        string memory title,
        string memory message
    ) public payable {
        IPUSHCommInterface(pushProtocolContractAddress)
            .sendNotification(
                admin, //AccountDelegate
                //  Broadcast => address(this) else specify address
                receiver,
                bytes(
                    string(
                        abi.encodePacked(
                            "0", //MinimalIdentity
                            "+", // segregator
                            "3", // 1: Broadcast; 3: Targeted
                            "+", // segregator
                            title, // this is notification title
                            "+", // segregator
                            message // notification body
                        )
                    )
                )
            );
        emit TargettedPushNotificationSent(receiver,title, message);
    }

    function sendBroadcast(
        string memory title,
        string memory message
    ) public payable {
        IPUSHCommInterface(pushProtocolContractAddress)
            .sendNotification(
                admin, //AccountDelegate
                //  Broadcast => address(this) else specify address
                address(this),
                bytes(
                    string(
                        abi.encodePacked(
                            "0", //MinimalIdentity
                            "+", // segregator
                            "1", // 1: Broadcast; 3: Targeted
                            "+", // segregator
                            title, // this is notification title
                            "+", // segregator
                            message // notification body
                        )
                    )
                )
            );
        emit NotificiationBroadcasted(title, message);
    }
}



// Sepolia PushProtocol Contract: 0x0C34d54a09CFe75BCcd878A469206Ae77E0fe6e7