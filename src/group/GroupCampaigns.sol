//SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @title GroupCampaigns
/// @author Dustin Stacy
/// @notice This contract implements a campaign management system for groups.
contract GroupCampaigns {
    /*///////////////////////////////////////////////////////////////
                             ERRORS
    ///////////////////////////////////////////////////////////////*/

    /// @notice Error to indicate that a campaign is over.
    error GroupCampaigns__CampaignOver();

    /// @notice Error to indicate that no slots are available.
    error GroupCampaigns__NoSlotsAvailable();

    /// @notice Error to indicate that not enough funds were sent.
    error GroupCampaigns__NotEnoughFunds();

    /// @notice Error to indicate that no pending sponsors exist.
    error GroupCampaigns__NoPendingSponsors();

    /// @notice Error to indicate the sponsor does not exist.
    error GroupCampaigns__SponsorDoesNotExist();

    /// @notice Error to indicate the sponsor funds transfer failed.
    error GroupCampaigns__FailedToSendFundsToSponsor();

    /// @notice Error to indicate that only the group host can call the function.
    error GroupCampaigns__OnlyGroupHost();

    /// @notice Error to indicate that the campaign has existing funds.
    error GroupCampaigns__FundingExists();

    /// @notice Error to indicate the protocol fee transfer failed.
    error GroupCampaigns__FailedToSendProtocolFee();

    /// @notice Error to indicate the group funds transfer failed.
    error GroupCampaigns__FailedToSendFundsToGroup();

    /// @notice Error to indicate that the campaign was not found.
    error GroupCampaigns__CampaignNotFound();

    /// @notice Error to indicate that no sponsors exist.
    error GroupCampaigns__NoSponsors();

    /// @notice Error to indicate that no pending funds exist.
    error GroupCampaigns__NoPendingFunds();

    /// @notice Error to indicate that no funds exist.
    error GroupCampaigns__NoFunds();

    /*///////////////////////////////////////////////////////////////
                             STATE VARIABLES
    ///////////////////////////////////////////////////////////////*/
    struct Campaign {
        uint256 id;
        address group;
        address host;
        string title;
        uint256 deadline;
        uint32 slotsAvailable;
        uint256 slotPrice;
        bool active;
    }

    struct Sponsor {
        address sponsor;
        uint256 amount;
        bool accepted;
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

    /// @notice A mapping of sponsor requests by campaign.
    mapping(uint256 campaignId => address[]) public campaignSponsorRequests;

    /// @notice A mapping of sponsors by campaign.
    mapping(uint256 campaignId => Sponsor[]) public campaignSponsors;

    /// @notice A mapping of sponsor request funds by campaign.
    mapping(uint256 campaignId => uint256 pendingFunds) public campaignPendingFunds;

    /// @notice A mapping of campaign balances.
    mapping(uint256 campaignId => uint256 balance) public campaignBalances;

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
        address host,
        string memory title,
        uint256 deadline,
        uint32 slotsAvailable,
        uint256 slotPrice
    ) external {
        Campaign memory newCampaign =
            Campaign(campaignCount, group, host, title, deadline, slotsAvailable, slotPrice, true);

        campaignById[campaignCount] = newCampaign;
        campaignsByGroup[group].push(newCampaign);

        emit CampaignCreated(campaignCount, group, title, deadline, slotsAvailable, slotPrice);

        campaignCount++;
    }

    /// @notice Allows a user to request to sponsor a campaign.
    /// @param campaignId The ID of the campaign.
    /// @param sponsor The address of the sponsor.
    function requestToSponsor(uint256 campaignId, address sponsor) public payable {
        Campaign storage campaign = campaignById[campaignId];
        if (block.timestamp > campaign.deadline) {
            revert GroupCampaigns__CampaignOver();
        } else if (campaign.slotsAvailable == 0) {
            revert GroupCampaigns__NoSlotsAvailable();
        } else if (msg.value < campaign.slotPrice) {
            revert GroupCampaigns__NotEnoughFunds();
        } else {
            campaign.slotsAvailable--;
            campaignPendingFunds[campaignId] += campaign.slotPrice;
            campaignSponsorRequests[campaignId].push(sponsor);
        }
    }

    /// @notice Allows a group host to accept a sponsor for a campaign.
    /// @param campaignId The ID of the campaign.
    /// @param sponsor The address of the sponsor.
    function acceptSponsor(uint256 campaignId, address sponsor) public {
        if (campaignSponsorRequests[campaignId].length == 0) {
            revert GroupCampaigns__NoPendingSponsors();
        } else {
            campaignSponsors[campaignId].push(Sponsor(sponsor, campaignById[campaignId].slotPrice, true));
            campaignBalances[campaignId] += campaignById[campaignId].slotPrice;
            campaignPendingFunds[campaignId] -= campaignById[campaignId].slotPrice;
        }
    }

    /// @notice Allows a group host to deny a sponsor for a campaign.
    /// @param campaignId The ID of the campaign.
    /// @param sponsor The address of the sponsor.
    function denySponsor(uint256 campaignId, address sponsor) public {
        uint256 length = campaignSponsorRequests[campaignId].length;
        if (length == 0) {
            revert GroupCampaigns__NoPendingSponsors();
        }

        /// @dev Start with a max value to indicate not found
        uint256 index = type(uint256).max;

        // Find the index of the sponsor to remove
        for (uint256 i = 0; i < length; i++) {
            if (campaignSponsorRequests[campaignId][i] == sponsor) {
                index = i;
                break;
            }
        }

        if (index > length) {
            revert GroupCampaigns__SponsorDoesNotExist();
        }

        // Swap with the last element and then pop
        campaignSponsorRequests[campaignId][index] = campaignSponsorRequests[campaignId][length - 1];
        campaignSponsorRequests[campaignId].pop();

        campaignPendingFunds[campaignId] -= campaignById[campaignId].slotPrice;
        (bool success,) = sponsor.call{value: campaignById[campaignId].slotPrice}("");
        if (!success) {
            revert GroupCampaigns__FailedToSendFundsToSponsor();
        }
    }

    /// @notice Allows a group host to update a campaign.
    /// @param campaignId The ID of the campaign.
    /// @param title The title of the campaign.
    /// @param deadline The deadline for the campaign.
    /// @param slotsAvailable The number of slots available in the campaign.
    /// @param slotPrice The price per slot in the campaign.
    function updateCampaign(
        uint256 campaignId,
        string memory title,
        uint256 deadline,
        uint32 slotsAvailable,
        uint256 slotPrice
    ) external {
        Campaign storage campaign = campaignById[campaignId];
        if (campaign.host != msg.sender) {
            revert GroupCampaigns__OnlyGroupHost();
        } else if (block.timestamp > campaign.deadline) {
            revert GroupCampaigns__CampaignOver();
        } else if (campaignBalances[campaignId] != 0) {
            revert GroupCampaigns__FundingExists();
        }

        campaign.title = title;
        campaign.deadline = deadline;
        campaign.slotsAvailable = slotsAvailable;
        campaign.slotPrice = slotPrice;
    }

    /// @notice Allows a group host to complete a campaign.
    /// @param campaignId The ID of the campaign.
    function completeCampaign(uint256 campaignId) public {
        Campaign storage campaign = campaignById[campaignId];
        if (block.timestamp < campaign.deadline) {
            // Campaign is not over
        }

        if (campaignBalances[campaignId] > 0) {
            uint256 remainingBalance = campaignBalances[campaignId];
            campaignBalances[campaignId] = 0;

            uint256 protocolFeeAmount = remainingBalance * protocolFee / 100;
            (bool success,) = protocolFeeDestination.call{value: protocolFeeAmount}("");
            if (!success) {
                revert GroupCampaigns__FailedToSendProtocolFee();
            }

            remainingBalance -= protocolFeeAmount;

            (bool success2,) = campaign.group.call{value: remainingBalance}("");
            if (!success2) {
                revert GroupCampaigns__FailedToSendFundsToGroup();
            }
        }

        campaign.active = false;
    }

    /// @notice Allows a group host to delete a campaign.
    /// @param campaignId The ID of the campaign.
    function deleteCampaign(uint256 campaignId) public {
        Campaign storage campaign = campaignById[campaignId];
        if (campaign.host != msg.sender) {
            revert GroupCampaigns__OnlyGroupHost();
        } else if (campaignBalances[campaignId] != 0) {
            revert GroupCampaigns__FundingExists();
        }

        delete campaignById[campaignId];
    }

    /*///////////////////////////////////////////////////////////////
                          PUBLIC FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    function tipCampaign(uint256 campaignId) public payable {
        campaignBalances[campaignId] += msg.value;
    }

    /*///////////////////////////////////////////////////////////////
                          GETTER FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /// @notice Gets a campaign by its ID.
    /// @param campaignId The ID of the campaign.
    function getCampaignById(uint256 campaignId) public view returns (Campaign memory) {
        if (campaignById[campaignId].id == 0) {
            revert GroupCampaigns__CampaignNotFound();
        } else {
            return campaignById[campaignId];
        }
    }

    /// @notice Gets all campaigns for a group.
    /// @param group The address of the group.
    function getGroupCampaigns(address group) public view returns (Campaign[] memory) {
        if (campaignsByGroup[group].length == 0) {
            revert GroupCampaigns__CampaignNotFound();
        } else {
            return campaignsByGroup[group];
        }
    }

    /// @notice Gets the sponsor requests for a campaign.
    /// @param campaignId The ID of the campaign.
    function getCampaignSponsorRequests(uint256 campaignId) public view returns (address[] memory) {
        if (campaignSponsorRequests[campaignId].length == 0) {
            revert GroupCampaigns__NoPendingSponsors();
        } else {
            return campaignSponsorRequests[campaignId];
        }
    }

    /// @notice Gets the sponsors for a campaign.
    /// @param campaignId The ID of the campaign.
    function getCampaignSponsors(uint256 campaignId) public view returns (Sponsor[] memory) {
        if (campaignSponsors[campaignId].length == 0) {
            revert GroupCampaigns__NoSponsors();
        } else {
            return campaignSponsors[campaignId];
        }
    }

    /// @notice Gets the pending funds for a campaign.
    /// @param campaignId The ID of the campaign.
    function getCampaignPendingFunds(uint256 campaignId) public view returns (uint256) {
        if (campaignPendingFunds[campaignId] == 0) {
            revert GroupCampaigns__NoPendingFunds();
        } else {
            return campaignPendingFunds[campaignId];
        }
    }

    /// @notice Gets the campaign balance.
    /// @param campaignId The ID of the campaign.
    function getCampaignBalance(uint256 campaignId) public view returns (uint256) {
        if (campaignBalances[campaignId] == 0) {
            revert GroupCampaigns__NoFunds();
        } else {
            return campaignBalances[campaignId];
        }
    }
}
