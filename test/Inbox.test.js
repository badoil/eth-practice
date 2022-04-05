// contract test code will go here
const assert = require('assert');
const ganache = require('ganache-cli');
const Web3 = require('web3'); // 요놈이 대문자 Web3인 이유는, web3 라이브러리의 constructor이기 때문,  instance를 만들기 위해 사용, 컨벤션인데 생성자 함수를 쓸때 대문자 씀, 일종의 클래스라고 생각해라
const web3 = new Web3(ganache.provider()); // Web3 객체에 가나쉬 프로바이더와 연결해라, 우리가 연결하고자 하는 네트워크에 따라 달라짐
const { interface, bytecode } = require('../compile');

let accounts;
let inbox;

beforeEach( async () => {
    // get a list of all accounts
    accounts = await web3.eth.getAccounts();
    inbox = await new web3.eth.Contract(JSON.parse(interface))  // 솔리디티가 컴파일되면서 만든 인터페이스를 제이슨에서 자바스크립트 오브젝트로 파싱
        .deploy({ data: bytecode, arguments: ['hi, there']})    // 우리가 만든 솔리디티 코드가 컨트랙트이고 이거를 바이트코드로 보냄. 그리고 그 생성자의 인자를 'hi, there'로 한것임, 즉 배포할 객체를 만듬
        .send({ from: accounts[0], gas: '1000000'});            // 만든 객체를 여기서 보냄, 웹3에서 네트워크로 보냄, 결국 inbox에 컨트랙트의 내용들이 담기는 것

    // use one of those accounts to deploy the contract
})

describe('Inbox', () => {
    it('deploys a contract', () => {
        assert.ok(inbox.options.address); // assert.ok : 이 객체가 존재한다
    });

    it('has a default message', async () => {
        const message = await inbox.methods.message().call();
        assert.equal(message, 'hi, there');
    })

    it('can change the message', async() => {
        await inbox.methods.setMessage('bye').send({ from: accounts[0] });
        const message = await inbox.methods.message().call();
        assert.equal(message, 'bye');
    })
});



/*
web3 버저닝 문제
0.x.x : primitive interface only callbacks for async code
1.x.x : support for promises async/await, 우리가 여기서 쓰는 신버전

구버전은 콜백만 지원하고 프라미스를 지원하지 않는다

ganache(이더네트워크)  <->  provider  <->  web3  : 프로바이더는 이 둘 사이의 일종의 연결자, 이때 웹3는 플러그인을 프로바이더에 제공(provide)해야 연결 가능
*/