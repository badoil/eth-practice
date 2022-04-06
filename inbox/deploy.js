// deploy code will go here
const HDWalletProvider = require('@truffle/hdwallet-provider');
const Web3 = require('web3');
// const { interface, bytecode } = require('./compile');
const { abi, evm } = require('./compile');

const provider = new HDWalletProvider(
    'cloud dice gold ignore estate portion keen carbon wall pen believe sudden', 
    'https://rinkeby.infura.io/v3/0c3faaaf0b984aa0b3a23ac42d6ad6f8');
const web3 = new Web3( provider);   // web3 객체로 이더를 보내거나, 컨트랙트 배포하거나, 컨트랙트 업뎃하거나 할 수 있음

const deploy = async() => {
    const account = await web3.eth.getAccounts();
    console.log('account: ', account[0]);

    // const result = await new web3.eth.Contract(JSON.parse(interface))
    //                 .deploy({ data: bytecode, arguments: ['hi, there']})
    //                 .send({ from: account[0], gas: '1000000'})
    const result = await new web3.eth.Contract(abi)
    .deploy({ data: evm.bytecode.object, arguments: ['hi, there'] })
    .send({ gas: '1000000', from: accounts[0] });

            
    console.log('address: ', result.options.address);
    provider.engine.stop();     // to prevent hanging deployment
};
deploy();

/*
@truffle/hdwallet-provider 
specify which account we unlock and use as source of ether for the deploying contract, 
And specity what outside node we are going to connect

*/