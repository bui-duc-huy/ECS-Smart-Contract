pragma solidity ^0.5.4;

contract ITreeFactory {
    event TreeCreated(uint Salt, address Tree);
    function deploy(bytes32 _initialRoot, uint _salt) public returns(address);
}
