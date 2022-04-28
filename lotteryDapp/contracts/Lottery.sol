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

    address payable public owner;

    uint256 constant internal BLOCK_LIMIT = 256;
    uint256 constant internal BET_BLOCK_INTERVAL = 3;
    uint256 constant internal BET_AMOUNT = 5 * 10**15;

    uint256 private _pot;
    bool private mode = false; // false: use answer for test, true: use real block hash
    bytes32 public answerForTest;

    event BET(uint256 index, address bettor, uint256 amount, bytes1 challenges, uint256 answerBlockNumber);
    event WIN(uint256 index, address bettor, uint256 amount, bytes1 challenges, bytes1 answer, uint256 answerBlockNumber);
    event FAIL(uint256 index, address bettor, uint256 amount, bytes1 challenges, bytes1 answer, uint256 answerBlockNumber);
    event DRAW(uint256 index, address bettor, uint256 amount, bytes1 challenges, bytes1 answer, uint256 answerBlockNumber);
    event REFUND(uint256 index, address bettor, uint256 amount, bytes1 challenges, uint256 answerBlockNumber);

    enum BlockStatus {Checkable, NotRevealed, BlockLimitPassed}
    enum BettingResult {Fail, Win, Draw}

    constructor() public {
        owner = msg.sender;
    }

    function getPot() public view returns(uint256) {
        return _pot;
    }

    /**
     * @dev 베팅과 정답체크를 동시에 한다. 유저는 0.005 이더를 보내고, 1바이트 글자를 보낸다
     *  큐에 저장된 베팅정보는 이후 distribute 함수에서 해결된다
     * @param challenges  유저가 보내는 1바이트 글자
     * @return 함수가 잘 수행되었는지 확인하는 boolean 값
     */
    function betAndDistribute(bytes1 challenges) public payable returns (bool) {
        bet(challenges);
        distribute();

        return true;
    }

    /**
     * @dev 베팅을 한다. 유저는 0.005 이더를 보내고, 1바이트 글자를 보낸다
     *  큐에 저장된 베팅정보는 이후 distribute 함수에서 해결된다
     * @param challenges  유저가 보내는 1바이트 글자
     * @return 함수가 잘 수행되어쓴지 확인하는 boolean 값
     */
    function bet(bytes1 challenges) public payable returns(bool) {    // 트랜잭션 기본 가스량 21000 가스
        // check the proper eth is sent
        require(msg.value == BET_AMOUNT, 'not enough money');

        // push bet to the queue
        require(pushBet(challenges), "failed to add this bet info");    // 60000가스

        // emit event, 이벤트 로그는 블록체인 함수로 호출하고 따로 모을 수 있음, web3.js 로 로그를 긁어올 수 있음, 프론트 만들면서 알 수 있음
        emit BET(_tail-1, msg.sender, msg.value, challenges, block.number+BET_BLOCK_INTERVAL);  // emit 자체가 375가스, 파라미터 등등 4~5000 가스 

        return true;
    }

    /**
     * @dev 베팅결과값을 확인하고 팟머니를 분배
     *  WIN, FAIL, DRAW 에 따른 분배
     */
    function distribute() public {
        uint256 cur;
        uint256 transferAmount;
        BetInfo memory b;
        BlockStatus currentBlockStatus;
        BettingResult currentBettingResult;

        for(cur=_head; cur<_tail; cur++) {
            b = _bets[cur];
            currentBlockStatus = getBlockStatus(b.answerBlockNumber);

            //checkable: block.number > answerBlockNumber && block.number - BLOCK_LIMIT <= answerBlockNumber
            if (currentBlockStatus == BlockStatus.Checkable) {
                bytes32 answerBlockHash = getAnswerBlockHash(b.answerBlockNumber);
                currentBettingResult = isMatch(b.challenges, answerBlockHash);
                // if win, bettor gets pot money
                if (currentBettingResult == BettingResult.Win) {
                    // transfer pot money to winner
                    transferAmount =  transferAfterPayingFee(b.bettor, _pot+BET_AMOUNT);
                    // make pot money to zero
                    _pot = 0;
                    // emit Win event
                    emit WIN(cur, b.bettor, transferAmount, b.challenges, answerBlockHash[0], b.answerBlockNumber);
                }

                // if fail, bettor's money goes to pot
                if (currentBettingResult == BettingResult.Fail) {
                    // pot = pot + BET_AMOUNT
                    _pot += BET_AMOUNT;
                    // emit Fail event
                    emit FAIL(cur, b.bettor, 0, b.challenges, answerBlockHash[0], b.answerBlockNumber);
                }

                // if draw, refund bettor's money
                if (currentBettingResult == BettingResult.Win) {
                    // transfer only BET_AMOUNT
                    transferAmount = transferAfterPayingFee(b.bettor, BET_AMOUNT);
                    
                    // emit Draw event
                    emit DRAW(cur, b.bettor, transferAmount, b.challenges, answerBlockHash[0], b.answerBlockNumber);
                }
            }
            //not revealed
            if (currentBlockStatus == BlockStatus.NotRevealed) {
                break;
            }
            //block limit passed
            if (currentBlockStatus == BlockStatus.BlockLimitPassed) {
                //refund
                transferAmount = transferAfterPayingFee(b.bettor, BET_AMOUNT);

                //emit refund
                emit REFUND(cur, b.bettor, transferAmount, b.challenges, b.answerBlockNumber);

            }
            popBet(cur);


        }
        _head = cur;  // popBet(cur)해서 줄어든 큐에 따라서 헤드도 최신화
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

        return BlockStatus.BlockLimitPassed;
    }

    function transferAfterPayingFee(address payable addr, uint256 amount) internal returns(uint256) {
        // uint256 fee = amount/100;
        uint256 fee = 0;

        uint256 amountWithoutFee = amount - fee;

        //transfer to addr
        addr.transfer(amountWithoutFee);

        //transfer to owner
        owner.transfer(fee);


        return amountWithoutFee;
    }

    function setAnswerForTest(bytes32 answer) public returns(bool result) {
        require(msg.sender == owner, "Only owner can set the answer for test mode");
        answerForTest = answer;
        return true; 
    }

    function getAnswerBlockHash(uint256 answerBlockNumber) internal view returns(bytes32) {
        return mode ? blockhash(answerBlockNumber): answerForTest;
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
        return BettingResult.Fail;
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