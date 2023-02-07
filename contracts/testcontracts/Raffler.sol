// // SPDX-License-Identifier: MIT

// pragma solidity ^0.8.0;

// import "./IERC20.sol";
// import "./Ownable.sol";

// contract Raffler is Ownable {

//     address public purchaseToken;
//     address public purchaseTokenSink;
//     uint public currentDeadline;

//     // TODO: This may actually increase usage
//     struct Raffle {
//         uint128 ticketCost; // TODO: Can reduce this integer size
//         // bool created;
//         bool started;
//         uint deadline; // TODO: Can reduce this integer size
//     }

//     // TODO: Think about whether it should be this way or the other way around.
//     // mapping(address => mapping(uint32 => uint)) private tickets;
//     mapping(uint32 => Raffle) private raffles;
//     uint32 private raffleCounter;

//     event EnterRaffle(
//         address indexed account,
//         uint32 indexed raffleId,
//         uint256 indexed amount
//     );

//     constructor() {

//     }

//     function setPurchaseToken(address token) external onlyOwner {
//         purchaseToken = token;
//     }

//     function setPurchaseTokenSink(address sink) external onlyOwner {
//         purchaseTokenSink = sink;
//     }

//     function createNewRaffle(uint endBlockNumber, uint128 cost) external onlyOwner returns (uint32 id) {
//         require(endBlockNumber > block.number, "Ends too soon.");
//         require(cost > 0, "Raffle tickets must have non-zero cost.");
//         Raffle memory r = Raffle(cost, false, endBlockNumber);
//         id = raffleCounter;
//         raffles[raffleCounter++] = r;
//     }

//     function startRaffle(uint32 raffleId) external onlyOwner {
//         Raffle storage r = raffles[raffleId];
//         require(r.deadline > 0, "Raffle of that ID doesn't exist.");
//         require(!r.started, "Raffle has already started.");
//         r.started = true;
//     }

//     function selectWinners() external onlyOwner {

//     }

//     function purchaseTickets(uint num, uint32 raffleId) external {
//         Raffle memory r = raffles[raffleId];
//         require(r.started && block.number <= r.deadline, "Raffle not active.");
//         IERC20(purchaseToken).transferFrom(msg.sender, purchaseTokenSink, num * r.ticketCost);
//         // tickets[msg.sender][raffleId] += num;

//     }

//     function selectWinnersSimple(uint numWinners, uint32 raffleId) external onlyOwner {

//     }

//     function selectWinnersChainlink(uint numWinners, uint32 raffleId) external onlyOwner {

//     }

//     function viewWinners(uint32 raffleId) external view returns (uint[] memory) {

//     }


//     /** View Functions */
//     function getTicketCost(uint32 raffleId) public view returns (uint128) {
//         return raffles[raffleId].ticketCost;
//     }

//     function getDeadline(uint32 raffleId) public view returns (uint) {
//         return raffles[raffleId].deadline;
//     }

//     function hasStarted(uint32 raffleId) public view returns (bool) {
//         return raffles[raffleId].started;
//     }

//     function getTickets(uint32 raffleId, address user) public view returns (uint) {
//         return tickets[user][raffleId];
//     }
// }