pragma solidity ^0.8.0;

import "./MintAnimalToken.sol";

contract SaleAnimalToken {
    MintAnimalToken public mintAnimalTokenAddress;

    constructor (address _mintAnimalTokenAddress) {
        mintAnimalTokenAddress = MintAnimalToken(_mintAnimalTokenAddress);
    }

    mapping(uint256 => uint256) public animalTokenPrices;
    uint256[] public onSaleAnimalTokenArray;

    function setForSaleAnimalToken(uint256 _animalTokenId, uint256 _price) public {
        address animalTokenOwner = mintAnimalTokenAddress.ownerOf(_animalTokenId);

        require(animalTokenOwner == msg.sender, "Caller is not animal token owner");
        require(_price > 0, "price is 0 or lower now");
        require(animalTokenPrices[_animalTokenId] == 0, "this animal token is already on sale");
        require(mintAnimalTokenAddress.isApprovedForAll(animalTokenOwner, address(this)), "animal token owner did not approve token");

        animalTokenPrices[_animalTokenId] = _price;
        onSaleAnimalTokenArray.push(_animalTokenId);
    }

    function purchaseAnimalToken(uint256 _animalTokenId) public payable {
        uint256 price = animalTokenPrices[_animalTokenId];
        address animalTokenOwner = mintAnimalTokenAddress.ownerOf(_animalTokenId);

        require(price > 0, "animal token is not for sale");
        require(price <= msg.value, "Caller sent lower than price");
        require(animalTokenOwner != msg.sender, "caller is animal token owener");

        payable(animalTokenOwner).send(msg.value);
        mintAnimalTokenAddress.safeTransferFrom(animalTokenOwner, msg.sender, _animalTokenId); // 소유권 이전

        animalTokenPrices[_animalTokenId] = 0;

        for (uint256 i=0; i<onSaleAnimalTokenArray.length; i++) {
            if (animalTokenPrices[onSaleAnimalTokenArray[i]] == 0) {
                onSaleAnimalTokenArray[i] = onSaleAnimalTokenArray[onSaleAnimalTokenArray.length-1];
                onSaleAnimalTokenArray.pop();
            }
        }
    }

    function getOnSaleAnimalTokenArrayLength() view public returns (uint256) {
        return onSaleAnimalTokenArray.length;
    }
}