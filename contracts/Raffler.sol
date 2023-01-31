// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Ownable.sol";

contract Raffler is Ownable {

    address public purchaseToken;
    uint public currentDeadline;

    struct Raffle {
        uint128 ticketCost;
        bool complete;
        uint deadline;
    }

    // TODO: Think about whether it should be this way or the other way around.
    mapping(address => mapping(uint32 => uint32)) private tickets;
    mapping(uint32 => Raffle) private raffles;
    uint32 private raffleCounter;

    constructor() {

    }

    function setPurchaseToken(address token) external onlyOwner {
        purchaseToken = token;
    }

    function startNewRaffle(uint endBlockNumber, uint128 cost) external onlyOwner {
        require(endBlockNumber > block.number, "Ends too soon.");
        raffles[raffleCounter++] = Raffle(cost, false, endBlockNumber);
    }

    function selectWinners() external onlyOwner {

    }

    function purchaseTickets(uint num, uint32 raffleNumber) external {

    }


    /** View Functions */
    function getTicketCost(uint32 raffleNumber) public view returns (uint128) {
        return raffles[raffleNumber].ticketCost;
    }

    function getDeadline(uint32 raffleNumber) public view returns (uint) {
        return raffles[raffleNumber].deadline;
    }

    function getTickets(uint32 raffleNumber, address user) public view returns (uint32) {
        return tickets[user][raffleNumber];
    }
}