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
    inbox = await new web3.eth.Contract(JSON.parse(interface))
        .deploy({ data: bytecode, arguments: ['hi, there']})
        .send({ from: accounts[0], gas: '1000000'});

    // use one of those accounts to deploy the contract
})

describe('Inbox', () => {
    it('deploys a contract', () => {
        console.log('inbox:', inbox);
    });
});



/*
web3 버저닝 문제
0.x.x : primitive interface only callbacks for async code
1.x.x : support for promises async/await, 우리가 여기서 쓰는 신버전

구버전은 콜백만 지원하고 프라미스를 지원하지 않는다

ganache(이더네트워크)  <->  provider  <->  web3  : 프로바이더는 이 둘 사이의 일종의 연결자, 이때 웹3는 플러그인을 프로바이더에 제공(provide)해야 연결 가능
*/