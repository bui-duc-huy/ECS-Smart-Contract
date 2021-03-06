pragma solidity ^0.5.4;
import "../bases/Identity.sol";
import "../interfaces/factories/IIdentityFactory.sol";

contract IdentityFactory is IIdentityFactory {
    function _getBytecode(address _owner, bytes32[] memory _keys, uint256[] memory _purposes) private pure returns (bytes memory) {
        bytes memory bytecode = type(Identity).creationCode;

        return abi.encodePacked(bytecode, abi.encode( _owner, _keys, _purposes));
    }

    function _deploy(bytes memory code, uint256 salt) private returns (address){
        address addr;
        assembly {
            addr := create2(0, add(code, 0x20), mload(code), salt)
            if iszero(extcodesize(addr)) {
            revert(0, 0)
            }
        }
        return addr;
    }

    function deploy(address _owner, bytes32[] memory _keys, uint256[] memory _purposes, uint _salt) public returns (address) {
        bytes memory bytecode = _getBytecode(_owner, _keys, _purposes);

        address identity = _deploy(bytecode, _salt);
        return identity;
    }

    function getAddress(address _owner, bytes32[] memory _keys, uint256[] memory _purposes, uint _salt) public view returns (address) {
        bytes memory bytecode = _getBytecode(_owner, _keys, _purposes);

        bytes32 hash = keccak256(abi.encodePacked(bytes1(0xff), address(this), _salt, keccak256(bytecode)));

        return address(uint160(uint(hash)));
    }
}
