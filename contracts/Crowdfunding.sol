// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @title CrowdfundingDapp
 * @dev A simple crowdfunding smart contract that allows project creators to create
 * campaigns and allows contributors to fund them.
 */
contract CrowdfundingDapp {
    // Campaign structure to store campaign details
    struct Campaign {
        address payable creator;
        string title;
        string description;
        uint256 goal;
        uint256 deadline;
        uint256 totalFunds;
        bool completed;
        bool claimed;
        mapping(address => uint256) contributions;
    }

    // Campaign ID counter
    uint256 public campaignCount;
    
    // Mapping from campaign ID to Campaign struct
    mapping(uint256 => Campaign) public campaigns;
    
    // Events
    event CampaignCreated(uint256 campaignId, address creator, string title, uint256 goal, uint256 deadline);
    event ContributionMade(uint256 campaignId, address contributor, uint256 amount);
    event FundsClaimed(uint256 campaignId, address creator, uint256 amount);
    event RefundIssued(uint256 campaignId, address contributor, uint256 amount);

    /**
     * @dev Creates a new crowdfunding campaign
     * @param _title Title of the campaign
     * @param _description Description of the campaign
     * @param _goal Funding goal in wei
     * @param _durationInDays Duration of the campaign in days
     */
    function createCampaign(
        string memory _title,
        string memory _description,
        uint256 _goal,
        uint256 _durationInDays
    ) public {
        require(_goal > 0, "Goal must be greater than 0");
        require(_durationInDays > 0, "Duration must be greater than 0");
        
        uint256 campaignId = campaignCount++;
        
        Campaign storage newCampaign = campaigns[campaignId];
        newCampaign.creator = payable(msg.sender);
        newCampaign.title = _title;
        newCampaign.description = _description;
        newCampaign.goal = _goal;
        newCampaign.deadline = block.timestamp + (_durationInDays * 1 days);
        newCampaign.totalFunds = 0;
        newCampaign.completed = false;
        newCampaign.claimed = false;
        
        emit CampaignCreated(campaignId, msg.sender, _title, _goal, newCampaign.deadline);
    }
    
    /**
     * @dev Allows users to contribute ETH to a campaign
     * @param _campaignId ID of the campaign to contribute to
     */
    function contribute(uint256 _campaignId) public payable {
        Campaign storage campaign = campaigns[_campaignId];
        
        require(block.timestamp < campaign.deadline, "Campaign has ended");
        require(!campaign.completed, "Campaign is already completed");
        require(msg.value > 0, "Contribution must be greater than 0");
        
        campaign.contributions[msg.sender] += msg.value;
        campaign.totalFunds += msg.value;
        
        // Check if the campaign goal has been reached
        if (campaign.totalFunds >= campaign.goal) {
            campaign.completed = true;
        }
        
        emit ContributionMade(_campaignId, msg.sender, msg.value);
    }
    
    /**
     * @dev Allows campaign creator to claim funds if the goal is reached
     * @param _campaignId ID of the campaign
     */
    function claimFunds(uint256 _campaignId) public {
        Campaign storage campaign = campaigns[_campaignId];
        
        require(msg.sender == campaign.creator, "Only campaign creator can claim funds");
        require(campaign.completed, "Campaign goal not reached yet");
        require(!campaign.claimed, "Funds have already been claimed");
        require(campaign.totalFunds > 0, "No funds to claim");
        
        campaign.claimed = true;
        uint256 amount = campaign.totalFunds;
        campaign.totalFunds = 0;
        
        campaign.creator.transfer(amount);
        
        emit FundsClaimed(_campaignId, msg.sender, amount);
    }
    
    /**
     * @dev Allows contributors to get refunds if campaign deadline passed and goal wasn't reached
     * @param _campaignId ID of the campaign
     */
    function getRefund(uint256 _campaignId) public {
        Campaign storage campaign = campaigns[_campaignId];
        
        require(block.timestamp >= campaign.deadline, "Campaign has not ended yet");
        require(!campaign.completed, "Campaign has reached its goal, no refunds");
        
        uint256 contributionAmount = campaign.contributions[msg.sender];
        require(contributionAmount > 0, "No contribution found");
        
        campaign.contributions[msg.sender] = 0;
        campaign.totalFunds -= contributionAmount;
        
        payable(msg.sender).transfer(contributionAmount);
        
        emit RefundIssued(_campaignId, msg.sender, contributionAmount);
    }
}
