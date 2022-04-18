// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Lottery {

    struct BetInfo {
        uint256 answerBlockNumber;
        address payable bettor;
        bytes challenges;
    }

    uint256 private _head;          // queue 구조를 만들고, 이를 hashMap과 함께 사용
    uint256 private _tail;
    mapping(uint256 => BetInfo) private _bets;

    address public owner;

    uint256 constant internal BLOCK_LIMIT = 256;
    uint256 constant internal BET_BLOCK_INTERVAL = 3;
    uint256 constant internal BET_AMOUNT = 5 * 10**15;

    uint256 private _pot;

    constructor() public {
        owner = msg.sender;
    }

    function getSomeValue() public pure returns(uint256 value) {
        return 5;
    }

    function getPot() public view returns(uint256 pot) {
        return _pot;
    }

    //betting, save the bet to the queue

    //distribute, check the answer, give the money to the winner

    function getBetInfo(uint256 index) public view returns(uint256 answerBlockNumber, address bettor, bytes memory challenges) {
        BetInfo memory b = _bets[index];
        answerBlockNumber = b.answerBlockNumber;
        bettor = b.bettor;
        challenges = b.challenges;
    }

    function pushBet(bytes memory challenges) public returns(bool) {    // 큐에 집어넣음
        BetInfo memory b;
        b.answerBlockNumber = block.number + BET_BLOCK_INTERVAL;
        b.bettor = payable(msg.sender);
        b.challenges = challenges;

        _bets[_tail] = b;
        _tail++;

        return true; 
    }

    function popBet(uint256 index) public returns(bool) {
        delete _bets[index];
        return true;
    }
}