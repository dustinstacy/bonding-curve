//SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract GroupCampaigns {
    struct Campaign {
        uint256 id;
        address group;
        string title;
        uint256 deadline;
        uint32 slotsAvailable;
        uint256 slotPrice;
        bool active;
    }

    uint256 public campaignCount;
    uint256 public protocolFee;
    address public protocolFeeDestination;

    mapping(address group => Campaign[]) public campaignsByGroup;
    mapping(uint256 campaignId => Campaign) public campaignById;

    event CampaignCreated(
        uint256 campaignId, address group, string title, uint256 deadline, uint32 slotsAvailable, uint256 slotPrice
    );

    constructor(uint256 _protocolFee, address _protocolFeeDestination) {
        protocolFee = _protocolFee;
        protocolFeeDestination = _protocolFeeDestination;
    }

    function createCampaign(
        address group,
        string memory title,
        uint256 deadline,
        uint32 slotsAvailable,
        uint256 slotPrice
    ) public {
        Campaign memory newCampaign = Campaign(campaignCount, group, title, deadline, slotsAvailable, slotPrice, true);

        campaignById[campaignCount] = newCampaign;
        campaignsByGroup[group].push(newCampaign);

        emit CampaignCreated(campaignCount, group, title, deadline, slotsAvailable, slotPrice);

        campaignCount++;
    }
}
