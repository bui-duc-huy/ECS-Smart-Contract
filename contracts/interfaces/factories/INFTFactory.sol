pragma solidity ^0.5.4;

contract INFTFactory {
    event NFTCreated(uint Salt, address NFT);
    function deploy(string memory _name, string memory _symbol, uint _salt) public returns(address);
}
