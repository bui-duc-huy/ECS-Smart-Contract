pragma solidity ^0.5.4;
import "./interfaces/factories/IIdentityFactory.sol";
import "./storage/EternalStorage.sol";
import "./interfaces/bases/IIdentity.sol";
import "./libraries/Ownable.sol";


contract UserController is Ownable {
    EternalStorage private _eternalStorage;
    string private _NFT_FACTORY = "NFT-FACTORY";
    string private _TREE_FACTORY = "TREE-FACTORY";
    string private _IDENTITY_FACTORY = "IDENTITY-FACTORY";

    string private _KEY_TO_IDENTITY = "KEY-IDENTITY";
    
    event MapIdentity(bytes32 Key, address Identity);
    event IdentityCreated(address Identity, address Owner);

    constructor (address _eternalStorageAddress) public {
        _eternalStorage = EternalStorage(_eternalStorageAddress);
    }

    function _mapIdentity(bytes32 _key, address _identity) private {
        bytes32 key = keccak256(abi.encode(_key, _KEY_TO_IDENTITY));
        _eternalStorage.set(key, _identity);
    }

    function _getUserIdentity(bytes32 _key) private view returns (address) {
        bytes32 key = keccak256(abi.encode(_key, _KEY_TO_IDENTITY));
        address identity = _eternalStorage.getAddressValue(key);
        return identity;
    }

    function registerIdentity(
        bytes32[] memory _keys,
        uint256[] memory _purposes,
        uint256 _salt
    )
    public
    {
        bytes32 factoryKey = keccak256(abi.encode(_IDENTITY_FACTORY));
        IIdentityFactory identityFactory = IIdentityFactory(_eternalStorage.getAddressValue(factoryKey));

        address newIdentity = identityFactory.deploy(msg.sender, _keys, _purposes, _salt);  
        _mapIdentity(keccak256(abi.encode(msg.sender)), newIdentity);

        emit IdentityCreated(newIdentity, tx.origin);
    }

    function mapIdentity(bytes32 _key, address _identity) public {
        _mapIdentity(_key, _identity);
        emit MapIdentity(_key, _identity);
    }

    function getUserIdentity(bytes32 _key) public view returns(address identity) {
        identity = _getUserIdentity(_key);
    }
    
    function getUserIdentity(address _owner) public view returns(address identity) {
        identity = _getUserIdentity(keccak256(abi.encode(_owner)));
    }
}
