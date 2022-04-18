const Lottery = artifacts.require("Lottery");
const assertRevert = require('./asserRevert');
const expectEvent = require('./expectEvent');

contract('Lottery', function([deployer, user1, user2]){     // ganache-cli -d -m tutorial 테스트환경으로 생성한 계정 10개중에 0,1,2 인덱스 해당하는 계정들이 들어옴
    let lottery;
    let betAmount = 5 * 10**15;
    let bet_block_interval = 3;

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

    describe.only('isMatch', function() {
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
})