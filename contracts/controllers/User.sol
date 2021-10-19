pragma solidity ^0.5.4;
import "../interfaces/factories/IIdentityFactory.sol";
import "../storage/EternalStorage.sol";
import "../interfaces/bases/IIdentity.sol";

contract UserController {
    EternalStorage private _eternalStorage;
    string private _NFT_FACTORY = "NFT-FACTORY";
    string private _TREE_FACTORY = "TREE-FACTORY";
    string private _IDENTITY_FACTORY = "IDENTITY-FACTORY";

    string private _ADDRESS_TO_IDENTITY = "ADDRESS-TO-IDENTITY";
    string private _KEY_TO_IDENTITY = "KEY-IDENTITY";

    event MapIdentity(bytes32 Key, address Identity);
    event IdentityCreated(address Identity, address Owner, address Creator);

    mapping(bytes32 => address) private _identities;


    constructor (address _eternalStorageAddress) public {
        _eternalStorage = EternalStorage(_eternalStorageAddress);
    }

    function _mapIdentity(bytes32 _key, address _identity) private {
        bytes32 key = keccak256(abi.encode(_key, _KEY_TO_IDENTITY));
        _eternalStorage.set(key, _identity);
    }

    function _mapIdentity(address _owner, address _identity) private {
        bytes32 key = keccak256(abi.encode(_owner, _ADDRESS_TO_IDENTITY));
        _eternalStorage.set(key, _identity);
    }

    function _getUserIdentity(address _owner) private view returns (address) {
        bytes32 key = keccak256(abi.encode(_owner, _ADDRESS_TO_IDENTITY));
        address identity = _eternalStorage.getAddressValue(key);
        return identity;
    }

    function _getUserIdentity(bytes32 _key) private view returns (address) {
        bytes32 key = keccak256(abi.encode(_key, _KEY_TO_IDENTITY));
        address identity = _eternalStorage.getAddressValue(key);
        return identity;
    }

    function registerIdentity(
        address _trustedIdentity,
        string memory _number,
        bytes32[] memory _initialKeys,
        bytes32[] memory _keys,
        uint256[] memory _purposes,
        address _owner,
        bytes32 _keyHash,
        uint256 _salt
    )
    public
    {
        bytes32 factoryKey = keccak256(abi.encode(_IDENTITY_FACTORY));
        IIdentityFactory identityFactory = IIdentityFactory(_eternalStorage.getAddressValue(factoryKey));

        address newIdentity = identityFactory.deploy(_owner, _keys, _purposes, _salt);  
        IIdentity identity = IIdentity(newIdentity);

        identity.setIdentityNumber(_trustedIdentity, _number);
        for (uint i = 0; i < _initialKeys.length; i++) {
            _mapIdentity(_initialKeys[i], newIdentity);
        }

        _mapIdentity(tx.origin, newIdentity);
    }

    function mapIdentity(bytes32 _key, address _identity) public {
        _mapIdentity(_key, _identity);
        emit MapIdentity(_key, _identity);
    }

    function getUserIdentity(address _owner) public view returns(address identity) {
        identity = _getUserIdentity(_owner);
    }

    function getUserIdentity(bytes32 _key) public view returns(address identity) {
        identity = _getUserIdentity(_key);
    }
}
