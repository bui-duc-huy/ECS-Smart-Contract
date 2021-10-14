pragma solidity ^0.5.4;
import "../storage/EternalStorage.sol";

contract UserController {
    EternalStorage private _eternalStorage;
    string private _NFT_FACTORY = "NFT-FACTORY";
    string private _TREE_FACTORY = "TREE-FACTORY";
    string private _IDENTITY_FACTORY = "IDENTITY-FACTORY";

    string private _GLOBAL_IDENTITY = "GLOBAL_IDENTITY";
    string private _KEY_IDENTITY = "KEY_IDENTITY";

    constructor (address _eternalStorageAddress) public {
        _eternalStorage = EternalStorage(_eternalStorageAddress);
    }

    function _setUserIdentity(address _identity, address _user, bytes32 _key) private {
    }

    function _setUserIdentity(address _identity, address _user, string memory _globalIdentifier) private {
    }

    function _updateIdentityKey(bytes32 _key) private {
    }

    function setUserIdentity(address _user, string memory _globlaIdentity) public {
    }

    function userRegisterIdentity(
        string memory _globalIdentifier,
        bytes32[] _keys,
        uint256[] _purposes,
        uint256 _timestamp,
        bytes32 _keyHash
    )
    public
    {
        bytes32 factoryKey = keccak256(abi.encode(_NFT_FACTORY));
        IdentityFactory identityFactory = IdentityFactory(_eternalStorage.getAddressValue(factoryKey));

        address newIdentity = identityFactory.deploy(_globalIdentifier, _keys, _purposes, _timestamp);  
    }
}
