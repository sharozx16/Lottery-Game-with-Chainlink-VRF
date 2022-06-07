//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@chainlink/contracts/src/v0.8/VRFConsumerBase.sol';

contract LotteryGame is VRFConsumerBase, Ownable {

 uint256 public fee;
 bytes32 public hashKey;

 address[] public players;
 uint8 maxPlayers;
 bool public gameStarted;
 uint256 entryFee;
 uint256 public gameID;

 event GameStarted(uint256 gameID, uint8 maxPlayers, uint256 entryFee);
 event PlayerJoined(uint256 gameID, address player);
 event GameEnded(uint256 gameID, address player, bytes32 requestID);

 constructor(address vrfCoordinator, address linkToken, bytes32 vrfKeyHash, uint256 vrfFee)
  VRFConsumerBase(vrfCoordinator,linkToken)
 {
   hashKey = vrfKeyHash;
   fee = vrfFee;
   gameStarted = false;
 }

 function startGame(uint8 _maxPlayers, uint256 _entryFee) public onlyOwner {
     require( !gameStarted, "Game is currently running");
     delete players;
     maxPlayers = _maxPlayers;
     gameStarted = true;
     entryFee = _entryFee;
     gameID += 1;

     emit GameStarted(gameID, maxPlayers, entryFee);
 }

 function joinGame() public payable{
     require( !gameStarted, "Game has not been started yet");
     require(msg.value == entryFee, "Value sent is not equal to entry Fee");
     require(players.length < maxPlayers, "game is full");
     players.push(msg.sender);
     emit PlayerJoined(gameID, msg.sender);
     if(players.length == maxPlayers){
         getRandomWinner();
     }
 }

 function fulfillRandomness( bytes32 requestId, uint256 randomness) internal virtual override{
     uint256 winnerIndex = randomness % players.length;
     address winner = players[winnerIndex];
     (bool sent, ) = winner.call{value: address(this).balance}("");
     require(sent, "Failed to send ether");
     emit GameEnded(gameID, winner, requestId);
     gameStarted = false;
     
 }

 function getRandomWinner() private returns (bytes32 requestId){
     require(LINK.balanceOf(address(this)) >= fee, "Not enough Link");
     return requestRandomness(hashKey, fee);
 }

 receive() external payable {}
 fallback() external payable {}

}