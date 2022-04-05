// deploy code will go here
const HDWalletProvider = require('@truffle/hdwallet-provider');
const Web3 = require('web3');
const { interface, bytecode } = require('./compile');

const provider = new HDWalletProvider(
    'cloud dice gold ignore estateportion  keen carbon wall penBelieve sudden', 
    'https://rinkeby.infura.io/v3/0c3faaaf0b984aa0b3a23ac42d6ad6f8');
const web3 = new Web3( provider);   // web3 객체로 이더를 보내거나, 컨트랙트 배포하거나, 컨트랙트 업뎃하거나 할 수 있음

/*
@truffle/hdwallet-provider 
specify which account we unlock and use as source of ether for the deploying contract, 
And specity what outside node we are going to connect

*/