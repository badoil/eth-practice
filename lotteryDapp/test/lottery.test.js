const Lottery = artifacts.require("Lottery");
const assertRevert = require('./asserRevert');
const expectEvent = require('./expectEvent');

contract('Lottery', function([deployer, user1, user2]){     // ganache-cli -d -m tutorial 테스트환경으로 생성한 계정 10개중에 0,1,2 인덱스 해당하는 계정들이 들어옴
    let lottery;
    let betAmount = 5 * 10**15;
    let bet_block_interval = 3;
    let betAmountBN = new web3.utils.BN('5000000000000000');

    beforeEach(async() => {
        lottery = await Lottery.new();      // 테스트환경에서 새롭게 배포한 컨트랙트
    })

    it('getPod should return current pod value', async() => {
        let pod = await lottery.getPot();
        console.log('pod: ', pod);
        assert.equal(pod, 0);
    })

    describe('Bet', function() {
        it('shold fail when the money is lower than 0.005 eth', async() => {
            // fail transaction
            await assertRevert(lottery.bet('0xab', {from: user1, value: 4000000000000000}));
        })

        it('should put the bet to the bet queue with 1 bet', async() => {
            // bet
            const receipt = await lottery.bet('0xab', {from: user1, value: betAmount});
            // console.log('receipt: ', receipt);

            let pot = await lottery.getPot();
            assert.equal(pot, 0);

            let contractBalance = await web3.eth.getBalance(lottery.address);
            assert.equal(contractBalance, betAmount);

            // check the bet info
            let currentBlockNumber = await web3.eth.getBlockNumber();
            let bet = await lottery.getBetInfo(0);
            assert.equal(bet.answerBlockNumber, currentBlockNumber + bet_block_interval);
            assert.equal(bet.bettor, user1);
            assert.equal(bet.challenges, '0xab');

            // check logs
            await expectEvent.inLogs(receipt.logs, 'BET');

        })
    })

    describe('isMatch', function() {
        let blockHash = '0xabb3d77bf528a9bd0326882b380b3615838169c15599dbbd4b09f07e107d6411';

        it('shoud be win when the two character is same', async() => {
            let isMatch = await lottery.isMatch('0xab', blockHash);
            console.log('isMatch:', isMatch);
            assert.equal(isMatch, 1);
        })

        it('shoud be fail when the two character is not same', async() => {
            let isMatch = await lottery.isMatch('0xcd', blockHash);
            console.log('isMatch:', isMatch);
            assert.equal(isMatch, 0);
        })

        it('shoud be win when the two character is same', async() => {
            let isMatch = await lottery.isMatch('0xac', blockHash);
            console.log('isMatch:', isMatch);
            assert.equal(isMatch, 2);
        })
    })

    describe('distribute', function() {
        describe('checkable', function() {
            it.only('win', async() => {
                // 테스트용 정답을 설정
                await lottery.setAnswerForTest('0xabb3d77bf528a9bd0326882b380b3615838169c15599dbbd4b09f07e107d6411', {from: deployer});

                await lottery.betAndDistribute('0xef', {from: user2, value: betAmount}); // block number 1 -> block number 4
                await lottery.betAndDistribute('0xef', {from: user2, value: betAmount}); // block number 2 -> block number 5
                await lottery.betAndDistribute('0xef', {from: user1, value: betAmount}); // block number 3 -> block number 6
                await lottery.betAndDistribute('0xef', {from: user2, value: betAmount}); // block number 4 -> block number 7
                await lottery.betAndDistribute('0xef', {from: user2, value: betAmount}); // block number 5 -> block number 8
                await lottery.betAndDistribute('0xef', {from: user2, value: betAmount}); // block number 6 -> block number 9

                let potBefore = await lottery.getPot(); // 0.01 eth, user2가 두번 베팅해서 팟에 0.005 * 2 들어감
                let user1BalanceBefore = await web3.eth.getBalance(user1);

                await lottery.betAndDistribute('0xef', {from: user2, value: betAmount}); // user1 이 정답을 맞추는데, 이것을 블록넘버 7인 이때 알 수 있음

                let potAfter = await lottery.getPot(); // 0.01 eth, user2가 두번 베팅해서 팟에 0.005 * 2 들어감
                let user1BalanceAfter = await web3.eth.getBalance(user1);

                // 팟 변화량 확인
                console.log('potBefore: ', potBefore.toString());
                // assert.equal(potBefore.toString(), new web3.utils.BN('10000000000000000').toString());
                // 위너 밸런스 확인

            })

            it('draw', async() => {

            })

            it('fail', async() => {

            })
        })

        describe('not revealed(not mined)', function() {
            
        })

        describe('block limit is passed', function() {
            
        })
    })
})