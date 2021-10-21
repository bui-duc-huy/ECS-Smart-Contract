pragma solidity ^0.5.4;
import "../interfaces/factories/IIdentityFactory.sol";
import "../storage/EternalStorage.sol";
import "../interfaces/bases/IIdentity.sol";

contract UserController {
    EternalStorage private _eternalStorage;
    string private _NFT_FACTORY = "NFT-FACTORY";
    string private _TREE_FACTORY = "TREE-FACTORY";
    string private _IDENTITY_FACTORY = "IDENTITY-FACTORY";

    string private _KEY_TO_IDENTITY = "KEY-IDENTITY";

    event MapIdentity(bytes32 Key, address Identity);
    event IdentityCreated(address Identity, address Owner, address Creator);

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

    function _issueClaim(address _trustedIdentity, address _claimHolder, uint256 _claimType, uint256 _schema, address _issuer, bytes memory _signature, bytes memory _data, string memory _uri) private returns(bytes32) {
        IIdentity trustedIdentity = IIdentity(_trustedIdentity);

        trustedIdentity.execute(_claimHolder, 0, abi.encodePacked(_claimType, _schema, _issuer, _signature, _data, _uri));
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

        _mapIdentity(keccak256(abi.encode(tx.origin)), newIdentity);
    }

    function mapIdentity(bytes32 _key, address _identity) public {
        _mapIdentity(_key, _identity);
        emit MapIdentity(_key, _identity);
    }

    function getUserIdentity(bytes32 _key) public view returns(address identity) {
        identity = _getUserIdentity(_key);
    }

    function issueClaim(address _trustedIdentity, address _claimHolder, uint256 _claimType, uint256 _schema, address _issuer, bytes memory _signature, bytes memory _data, string memory _uri) public {
        _issueClaim(_trustedIdentity, _claimHolder, _claimType, _schema, _issuer, _signature, _data, _uri);
    }
}
