const Migrations = artifacts.require("Migrations");  // 빌드 폴더의 Migration.json 파일 가져옴

module.exports = function(deployer) {   // truffle-config.js 에서 사용할 이더리움 주소를 세팅하고, 그 주소가 여기 deployer에 주입됨
  deployer.deploy(Migrations);    // Migration 의 바이트코드를 deployer가 deploy 함
};
