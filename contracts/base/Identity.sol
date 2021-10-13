pragma solidity ^0.5.4;
import "../libraries/ClaimManager.sol";
import "../libraries/KeyManager.sol";
import "../libraries/Encoder.sol";

contract Identity is KeyManager, ClaimManager {
    string public globalIdentifierNumber;
    
    constructor(string memory _globalIdentifierNumber, bytes32[] memory _keys, uint256[] memory _purposes) public {
        globalIdentifierNumber = _globalIdentifierNumber;
        
        addKeys(_keys, _purposes, ECDSA_TYPE);
    }

    function addKeys(bytes32[] memory _keys, uint256[] memory _purposes, uint256 _keyType) public returns (bool success) {
        _addKey(addrToKey(tx.origin), 1, _keyType);
        for (uint i = 0; i < _keys.length; i++) {
            _addKey(_keys[i], _purposes[i], _keyType);
        }
        
        return true;
    }
}