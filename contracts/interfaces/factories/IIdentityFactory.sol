pragma solidity ^0.5.4;

contract IIdentityFactory {
    function deploy(address _owner, bytes32[] memory _keys, uint256[] memory _purposes, uint _salt) public returns(address);
}
