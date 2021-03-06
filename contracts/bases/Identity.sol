pragma solidity ^0.5.4;
pragma experimental ABIEncoderV2;
import "../libraries/ClaimManager.sol";
import "../libraries/KeyManager.sol";
import "../libraries/Encoder.sol";
import "../interfaces/bases/IIdentity.sol";

contract Identity is KeyManager, ClaimManager, IIdentity {
    constructor(address _owner, bytes32[] memory _keys, uint256[] memory _purposes) public {
        _addKey(addrToKey(_owner), 1, ECDSA_TYPE);
        addKeys(_keys, _purposes, ECDSA_TYPE);
    }

    function addKeys(bytes32[] memory _keys, uint256[] memory _purposes, uint256 _keyType) public returns (bool success) {
        for (uint i = 0; i < _keys.length; i++) {
            _addKey(_keys[i], _purposes[i], _keyType);
        }
        
        return true;
    }

    function executeMany(address[] memory _tos, uint256[] memory _values, bytes[] memory _datas) public {
        for (uint i = 0; i < _tos.length; i++) {
            execute(_tos[i], _values[i], _datas[i]);
        }
    }
}
