// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract Project {
    //项目状态
    enum ProjectState {
        Ongoing,
        Successful,
        Failed
    }
    //当前项目状态
    ProjectState public state;
    //项目创建者地址
    address public creator;
    //项目描述
    string public description;
    //目标金额
    uint256 public goalAmount;
    //截止日期(事件戳)
    uint256 public deadline;
    //当前筹集金额
    uint256 public currentAmount;
    //捐赠结构
    struct Donation {
        address donor;
        uint256 amount;
    }
    //捐赠记录数组
    Donation[] public donations;

    //捐赠事件
    event DonationReceived(address indexed donor, uint256 amount);
    //项目状态变化事件
    event ProjectStateChanged(ProjectState newState);
    //资金提取事件
    event FundsWithdrawn(address indexed creator, uint256 amount);
    //资金撤回事件
    event FundsRefunded(address indexed donor, uint256 amount);

    function initialize(
        address _creator,
        string memory _description,
        uint256 _goalAmount,
        uint256 _duration
    ) public {
        creator = _creator;
        description = _description;
        goalAmount = _goalAmount;
        deadline = block.timestamp + _duration;
        state = ProjectState.Ongoing;
    }

    function donate() external payable {
        require(state == ProjectState.Ongoing, "project not going");
        require(block.timestamp < deadline, "project deadline pass");

        donations.push(Donation({donor: msg.sender, amount: msg.value}));
        currentAmount += msg.value;
        emit DonationReceived(msg.sender, msg.value);
    }

    modifier onlyCreator() {
        require(msg.sender == creator, "Not creator");
        _;
    }

    modifier onlyAfterDeadline() {
        require(block.timestamp > deadline, "project not finish");
        _;
    }

    function withdrawFunds() external onlyCreator onlyAfterDeadline {
        uint256 balance = address(this).balance;
        payable(creator).transfer(balance);

        emit FundsWithdrawn(creator, balance);
    }

    function refund() external onlyAfterDeadline {
        require(state == ProjectState.Failed, "project is going");

        uint256 refund = 0;
        for (uint256 i = 0; i < donations.length; i++) {
            if (donations[i].donor == msg.sender) {
                refund += donations[i].aomunt;
                donations[i].amount = 0;
            }
        }

        require(refund > 0, "no funds to refund");
        payable(msg.sender).transfer(refund);
        emit FundsRefunded(msg.sender, refund);
    }

    function updateProjectState() external onlyAfterDeadline {
        require(state == ProjectState.Ongoing, "project is finish");

        if (currentAmount >= goalAmount) {
            state = ProjectState.Successful;
        } else {
            state == ProjectState.Failed;
        }

        emit ProjectStateChanged(state);
    }
}
