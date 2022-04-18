// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Lottery {

    struct BetInfo {
        uint256 answerBlockNumber;
        address payable bettor;
        bytes1 challenges;
    }

    uint256 private _head;          // queue 구조를 만들고, 이를 hashMap과 함께 사용
    uint256 private _tail;
    mapping(uint256 => BetInfo) private _bets;

    address public owner;

    uint256 constant internal BLOCK_LIMIT = 256;
    uint256 constant internal BET_BLOCK_INTERVAL = 3;
    uint256 constant internal BET_AMOUNT = 5 * 10**15;

    uint256 private _pot;

    event BET(uint256 index, address bettor, uint256 amount, bytes1 challenges, uint256 answerBlockNumber);

    enum BlockStatus {Checkable, NotRevealed, BlockLimitPassed}
    enum BettingResult {Fail, Win, Draw}

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
    function bet(bytes1 challenges) public payable returns(bool) {    // 트랜잭션 기본 가스량 21000 가스
        // check the proper ith is sent
        require(msg.value == BET_AMOUNT, 'not enough money');

        // push bet to the queue
        require(pushBet(challenges), "failed to add this bet info");    // 60000가스

        // emit event, 이벤트 로그는 블록체인 함수로 호출하고 따로 모을 수 있음, web3.js 로 로그를 긁어올 수 있음, 프론트 만들면서 알 수 있음
        emit BET(_tail-1, msg.sender, msg.value, challenges, block.number+BET_BLOCK_INTERVAL);  // emit 자체가 375가스, 파라미터 등등 4~5000 가스 

        return true;
    }

    // distribute

    function distribute() public {
        uint256 cur;
        BetInfo memory b;
        BlockStatus currentBlockStatus;

        for(cur=_head; cur<_tail; cur++) {
            b = _bets[cur];
            currentBlockStatus = getBlockStatus(b.answerBlockNumber);

            //checkable: block.number > answerBlockNumber && block.number - BLOCK_LIMIT <= answerBlockNumber
            if (currentBlockStatus == BlockStatus.Checkable) {
                // if win, bettor gets pot money

                // if fail, bettor's money goes to pot

                // if draw, refund bettor's money
            }
            //not revealed
            if (currentBlockStatus == BlockStatus.NotRevealed) {
                break;
            }
            //block limit passed
            if (currentBlockStatus == BlockStatus.BlockLimitPassed) {
                //refund
                //emit refund

            }
            popBet(cur);


        }
    }

    function getBlockStatus(uint256 answerBlockNumber) internal view returns(BlockStatus) {
        //  현재 블록에서, 큐에 담겨있는 베팅의 당첨 여부를 알 수 있는 경우
        if (block.number > answerBlockNumber && block.number - BLOCK_LIMIT < answerBlockNumber) {
            return BlockStatus.Checkable;
        }

        // 현재 블록이 생성중이라 당첨 여부를 알려 줄 수 없음
        if (block.number <= answerBlockNumber) {
            return BlockStatus.NotRevealed;
        }

        // 너무 옛날 블록에 적힌 베팅 정보라 당첨 여부를 알려 줄 수 없음
        if (block.number > answerBlockNumber && block.number - BLOCK_LIMIT >= answerBlockNumber) {
            return BlockStatus.BlockLimitPassed;
        }
    }

    /**
     * @dev 정답확인
     * @param challenges  베팅 글자
     * @param answer 블록해쉬값
     * @return 정답결과
     */
    function isMatch(bytes1 challenges, bytes32 answer) public pure returns(BettingResult) {
        bytes1 c1 = challenges;
        bytes1 c2 = challenges;

        bytes1 a1 = answer[0];
        bytes1 a2 = answer[0];

        c1 = c1 >> 4; // 0xab -> 0x0a
        c1 = c1 << 4; // 0x0a -> 0xa0

        a1 = a1 >> 4;
        a1 = a1 << 4;

        c2 = c2 << 4; // 0xab -> 0xb0
        c2 = c2 >> 4; // 0xb0 -> 0x0b

        a2 = a2 << 4;
        a2 = a2 >> 4;

        if (c1 == a1 && c2 == a2) {
            return BettingResult.Win;
        }

        if (c1 == a1 || c2 == a2) {
            return BettingResult.Draw;
        }

    }

    //distribute, check the answer, give the money to the winner

    function getBetInfo(uint256 index) public view returns(uint256 answerBlockNumber, address bettor, bytes1 challenges) {
        BetInfo memory b = _bets[index];
        answerBlockNumber = b.answerBlockNumber;
        bettor = b.bettor;
        challenges = b.challenges;
    }

    function pushBet(bytes1 challenges) internal returns(bool) {    // 큐에 집어넣음, 총 60000가스
        BetInfo memory b;
        b.answerBlockNumber = block.number + BET_BLOCK_INTERVAL;    // 32bytes  20000 가스
        b.bettor = msg.sender;                                      // 20bytes  20000 가스
        b.challenges = challenges;                                  // byte

        _bets[_tail] = b;   // 위의 변수들이 실제로 블록에 저장되는 연산
        _tail++;            // 32bytes  20000 가스

        return true; 
    }

    function popBet(uint256 index) internal returns(bool) {
        delete _bets[index];
        return true;
    }
}