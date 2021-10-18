pragma solidity ^0.5.4;
import "../bases/PartialMerkleTreeImplementation.sol";
import "../interfaces/factories/ITreeFactory.sol";

contract TreeFactory is ITreeFactory {
    function _getBytecode(bytes32 _initialRoot) private pure returns (bytes memory) {
        bytes memory bytecode = type(PartialMerkleTreeImplementation).creationCode;

        return abi.encodePacked(bytecode, abi.encode(_initialRoot));
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

    function deploy(bytes32 _initialRoot, uint _salt) public returns (address) {
        bytes memory bytecode = _getBytecode(_initialRoot);

        address tree = _deploy(bytecode, _salt);

        emit TreeCreated(_salt, tree);
        return tree;
    }

    function getAddress(bytes32 _initialRoot, uint _salt) public view returns (address) {
        bytes memory bytecode = _getBytecode(_initialRoot);

        bytes32 hash = keccak256(abi.encodePacked(bytes1(0xff), address(this), _salt, keccak256(bytecode)));

        return address(uint160(uint(hash)));
    }
}
