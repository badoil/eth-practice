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

    event BET(uint256 index, address bettor, uint256 amount, bytes challenges, uint256 answerBlockNumber);

    constructor() public {
        owner = msg.sender;
    }

    function getPot() public view returns(uint256 pot) {
        return _pot;
    }

    /**
     * @dev 베팅을 한다. 유저는 0.005 이더를 보내고, 1바이트 글자를 보낸다
     *  큐에 저장된 베팅정보는 이후 distribute 함수에서 해결된다
     * @param challenges  유저가 보내는 1바이트 글자
     * @return 함수가 잘 수행되어쓴지 확인하는 boolean 값
     */
    function bet(bytes memory challenges) public payable returns(bool) {
        // check the proper ith is sent
        require(msg.value == BET_AMOUNT, 'not enough money');

        // push bet to the queue
        require(pushBet(challenges), "failed to add this bet info");

        // emit event, 이벤트 로그는 블록체인 함수로 호출하고 따로 모을 수 있음, web3.js 로 로그를 긁어올 수 있음, 프론트 만들면서 알 수 있음
        emit BET(_tail-1, msg.sender, msg.value, challenges, block.number+BET_BLOCK_INTERVAL);

        return true;
    }

    //distribute, check the answer, give the money to the winner

    function getBetInfo(uint256 index) public view returns(uint256 answerBlockNumber, address bettor, bytes memory challenges) {
        BetInfo memory b = _bets[index];
        answerBlockNumber = b.answerBlockNumber;
        bettor = b.bettor;
        challenges = b.challenges;
    }

    function pushBet(bytes memory challenges) internal returns(bool) {    // 큐에 집어넣음
        BetInfo memory b;
        b.answerBlockNumber = block.number + BET_BLOCK_INTERVAL;
        b.bettor = msg.sender;
        b.challenges = challenges;

        _bets[_tail] = b;
        _tail++;

        return true; 
    }

    function popBet(uint256 index) internal returns(bool) {
        delete _bets[index];
        return true;
    }
}