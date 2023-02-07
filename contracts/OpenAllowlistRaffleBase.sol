//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "./VRFCoordinatorV2Interface.sol";
import "./VRFConsumerBaseV2.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./Address.sol";

error AlreadyDrawn();
error DrawScriptNotSet();

/**                                     ..',,;;;;:::;;;,,'..
                                 .';:ccccc:::;;,,,,,;;;:::ccccc:;'.
                            .,:ccc:;'..                      ..';:ccc:,.
                        .':cc:,.                                    .,ccc:'.
                     .,clc,.                                            .,clc,.
                   'clc'                                                    'clc'
                .;ll,.                                                        .;ll;.
              .:ol.                                                              'co:.
             ;oc.                                                                  .co;
           'oo'                                                                      'lo'
         .cd;                                                                          ;dc.
        .ol.                                                                 .,.        .lo.
       ,dc.                                                               'cxKWK;         cd,
      ;d;                                                             .;oONWMMMMXc         ;d;
     ;d;                                                           'cxKWMMMMMMMMMXl.        ;x;
    ,x:            ;dxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx0NMMMMMMMMMMMMMMNd.        :x,
   .dc           .lXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNd.        cd.
   ld.          .oNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXkl'         .dl
  ,x;          .xWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN0d:.             ;x,
  oo.         .kWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKxc'.                .oo
 'x:          .kWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOo;.                     :x'
 :x.           .xWMMMMMMMMMMM0occcccccccccccccccccccccccccccccccccccc:'                         .x:
 lo.            .oNMMMMMMMMMX;                                                                  .ol
.ol              .lXMMMMMMMWd.  ,dddddddddddddddo;.   .:dddddddddddddo,                          lo.
.dl                cXMMMMMM0,  'OMMMMMMMMMMMMMMNd.   .xWMMMMMMMMMMMMXo.                          ld.
.dl                 ;KMMMMNl   oWMMMMMMMMMMMMMXc.   ,OWMMMMMMMMMMMMK:                            ld.
 oo                  ,OWMMO.  ,KMMMMMMMMMMMMW0;   .cKMMMMMMMMMMMMWO,                             oo
 cd.                  'kWX:  .xWMMMMMMMMMMMWx.  .dKNMMMMMMMMMMMMNd.                             .dc
 ,x,                   .dd.  ;KMMMMMMMMMMMXo.  'kWMMMMMMMMMMMMMXl.                              ,x;
 .dc                     .   .,:loxOKNWMMK:   ;0WMMMMMMMMMMMMW0;                                cd.
  :d.                      ...      ..,:c'  .lXMMMMMMMMMMMMMWk'                                .d:
  .dl                      :OKOxoc:,..     .xNMMMMMMMMMMMMMNo.                                 cd.
   ;x,                      ;0MMMMWWXKOxoclOWMMMMMMMMMMMMMKc                                  ,x;
    cd.                      ,OWMMMMMMMMMMMMMMMMMMMMMMMMWO,                                  .dc
    .oo.                      .kWMMMMMMMMMMMMMMMMMMMMMMNx.                                  .oo.
     .oo.                      .xWMMMMMMMMMMMMMMMMMMMMXl.                                  .oo.
      .lo.                      .oNMMMMMMMMMMMMMMMMMW0;                                   .ol.
       .cd,                      .lXMMMMMMMMMMMMMMMWk'                                   ,dc.
         ;dc.                      :KMMMMMMMMMMMMNKo.                                  .cd;
          .lo,                      ;0WWWWWWWWWWKc.                                   'ol.
            ,ol.                     .,,,,,,,,,,.                                   .lo,
             .;oc.                                                                .co:.
               .;ol'                                                            'lo;.
                  ,ll:.                                                      .:ll,
                    .:ll;.                                                .;ll:.
                       .:ll:,.                                        .,:ll:.
                          .,:ccc;'.                              .';ccc:,.
                              .';cccc::;'...            ...';:ccccc;'.
                                    .',;::cc::cc::::::::::::;,..
                                              ........

 * @title Base contract for an open allowlist raffle
 * @author Augminted Labs, LLC
 * @notice Winners are calculated deterministically off-chain using a provided script
 */
contract OpenAllowlistRaffleBase is Ownable, Pausable, VRFConsumerBaseV2 {
    using Address for address;

    struct VrfRequestConfig {
        bytes32 keyHash;
        uint64 subId;
        uint32 callbackGasLimit;
        uint16 requestConfirmations;
    }

    struct Raffle {
        uint256 seed;
        uint256 totalEntries;
        uint256 cost;
        uint256 numberOfWinners;
        bool drawn;
    }

    event EnterRaffle(
        address indexed account,
        uint256 indexed amount,
        uint256 indexed raffleNumber
    );

    event CreateRaffle(
        uint256 indexed cost,
        uint256 indexed numberOfWinners,
        uint256 indexed raffleId
    );

    VrfRequestConfig public vrfRequestConfig;
    string public drawScriptURI;
    
    mapping(uint256 => Raffle) public raffles;
    mapping(uint256 => uint256) public requestIdToRaffleId;
    uint256 public currentRaffleId;

    VRFCoordinatorV2Interface internal immutable COORDINATOR;

    constructor(address vrfCoordinator) VRFConsumerBaseV2(vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
    }

    /**
     * @notice Set configuration data for Chainlink VRF
     * @param _vrfRequestConfig Struct with updated configuration values
     */
    function setVrfRequestConfig(VrfRequestConfig memory _vrfRequestConfig) public onlyOwner {
        vrfRequestConfig = _vrfRequestConfig;
    }

    /**
     * @notice Set URI for script used to determine winners
     * @param uri IPFS URI for determining the winners
     */
    function setDrawScriptURI(string calldata uri) public onlyOwner {
        drawScriptURI = uri;
    }

    /**
     * @notice Flip paused state to disable entry
     */
    function flipPaused() public onlyOwner {
        paused() ? _unpause() : _pause();
    }

    function createNewRaffle(uint256 numberOfWinners, uint256 cost) public onlyOwner returns(uint256) {
        uint256 raffleId = currentRaffleId;
        currentRaffleId++;

        Raffle storage r = raffles[raffleId];
        r.cost = cost;
        r.numberOfWinners = numberOfWinners;
        emit CreateRaffle(cost, numberOfWinners, raffleId);
        return raffleId;
    }

    /**
     * @notice Add specified amount of entries into the raffle
     * @param amount Amount of entries to add
     * @param raffleId The raffle to join
     */
    function enter(uint256 amount, uint256 raffleId) internal {
        if (raffles[raffleId].drawn) revert AlreadyDrawn();

        raffles[raffleId].totalEntries += amount;

        emit EnterRaffle(_msgSender(), amount, raffleId);
    }

    /**
     * @notice Set seed for drawing winners
     * @dev Must set the deterministic draw script before to ensure fairness
     * @param raffleId The id of the raffle to draw
     */
    function draw(uint256 raffleId) public onlyOwner {
        if (raffles[raffleId].drawn) revert AlreadyDrawn();
        if (bytes(drawScriptURI).length == 0) revert DrawScriptNotSet();

        uint256 requestId = COORDINATOR.requestRandomWords(
            vrfRequestConfig.keyHash,
            vrfRequestConfig.subId,
            vrfRequestConfig.requestConfirmations,
            vrfRequestConfig.callbackGasLimit,
            1 // number of random words
        );
        requestIdToRaffleId[requestId] = raffleId;
    }

    /**
     * @inheritdoc VRFConsumerBaseV2
     */
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        uint256 raffleId = requestIdToRaffleId[requestId];
        Raffle storage r = raffles[raffleId];
        r.seed = randomWords[0];
        r.drawn = true;
    }
}