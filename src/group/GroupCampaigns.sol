//SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @title GroupCampaigns
/// @author Dustin Stacy
/// @notice This contract implements a campaign management system for groups.
contract GroupCampaigns {
    /*///////////////////////////////////////////////////////////////
                             STATE VARIABLES
    ///////////////////////////////////////////////////////////////*/
    struct Campaign {
        uint256 id;
        address group;
        string title;
        uint256 deadline;
        uint32 slotsAvailable;
        uint256 slotPrice;
        bool active;
    }

    /// @notice The total number of campaigns created.
    uint256 public campaignCount;

    /// @notice The fee charged by the protocol for completing a campaign.
    uint256 public protocolFee;

    /// @notice The address where protocol fees are sent.
    address public protocolFeeDestination;

    /// @notice A mapping of campaigns by group.
    mapping(address group => Campaign[]) public campaignsByGroup;

    /// @notice A mapping of campaigns by ID.
    mapping(uint256 campaignId => Campaign) public campaignById;

    /*///////////////////////////////////////////////////////////////
                                EVENTS
    ///////////////////////////////////////////////////////////////*/

    /// @notice Event to log the creation of a new campaign.
    event CampaignCreated(
        uint256 campaignId, address group, string title, uint256 deadline, uint32 slotsAvailable, uint256 slotPrice
    );

    /*///////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    ///////////////////////////////////////////////////////////////*/

    /// @notice Initializes the contract with the protocol fee and destination address.
    /// @param _protocolFee The fee charged by the protocol for completing a campaign.
    /// @param _protocolFeeDestination The address where protocol fees are sent.
    constructor(uint256 _protocolFee, address _protocolFeeDestination) {
        protocolFee = _protocolFee;
        protocolFeeDestination = _protocolFeeDestination;
    }

    /*///////////////////////////////////////////////////////////////
                          EXTERNAL FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /// @notice Creates a new campaign.
    /// @param group The address of the group creating the campaign.
    /// @param title The title of the campaign.
    /// @param deadline The deadline for the campaign.
    /// @param slotsAvailable The number of slots available in the campaign.
    /// @param slotPrice The price per slot in the campaign.
    function createCampaign(
        address group,
        string memory title,
        uint256 deadline,
        uint32 slotsAvailable,
        uint256 slotPrice
    ) external {
        Campaign memory newCampaign = Campaign(campaignCount, group, title, deadline, slotsAvailable, slotPrice, true);

        campaignById[campaignCount] = newCampaign;
        campaignsByGroup[group].push(newCampaign);

        emit CampaignCreated(campaignCount, group, title, deadline, slotsAvailable, slotPrice);

        campaignCount++;
    }

    /*///////////////////////////////////////////////////////////////
                          GETTER FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /// @notice Gets a campaign by its ID.
    /// @param campaignId The ID of the campaign.
    function getCampaignById(uint256 campaignId) public view returns (Campaign memory) {
        return campaignById[campaignId];
    }

    /// @notice Gets all campaigns for a group.
    /// @param group The address of the group.
    function getGroupCampaigns(address group) public view returns (Campaign[] memory) {
        return campaignsByGroup[group];
    }
}
