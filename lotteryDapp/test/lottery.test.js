const Lottery = artifacts.require("Lottery");

contract('Lottery', function([deployer, user1, user2]){     // ganache-cli -d -m tutorial 테스트환경으로 생성한 계정 10개중에 0,1,2 인덱스 해당하는 계정들이 들어옴
    let lottery;
    beforeEach(async() => {
        console.log('before');
        lottery = await Lottery.new();      // 테스트환경에서 새롭게 배포한 컨트랙트
    })

    it('basic', async() => {
        console.log('basic');
        let value = await lottery.getSomeValue();
        let owner = await lottery.owner();
        console.log('value: ', value);
        console.log('owner: ', owner);
    })

    it('getPod should return current pod value', async() => {
        let pod = await lottery.getPot();
        console.log('pod: ', pod);
        assert.equal(pod, 0);
    })
})