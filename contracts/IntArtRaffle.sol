//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./IERC721.sol";
import "./OpenAllowlistRaffleBase.sol";

error MustBeAKing();

interface IInt is IERC20 {}

contract IntArtRaffle is OpenAllowlistRaffleBase {
    IInt public immutable INT_TOKEN;
    address private sinkAddress;

    constructor(address intAddy, address vrfCoordinator) OpenAllowlistRaffleBase(vrfCoordinator) {
        INT_TOKEN = IInt(intAddy);
        sinkAddress = address(0);
    }

    /**
     * @notice Purchase entries into the raffle with $INT
     * @param amount Amount of entries to purchase
     */
    function enterWithInt(uint256 amount, uint256 raffleId) public whenNotPaused {
        uint256 cost = raffles[raffleId].cost;
        INT_TOKEN.transferFrom(_msgSender(), sinkAddress, amount * cost);
        OpenAllowlistRaffleBase.enter(amount, raffleId);
    }

    function setSinkAddress(address sink) external onlyOwner {
        sinkAddress = sink;
    }
}