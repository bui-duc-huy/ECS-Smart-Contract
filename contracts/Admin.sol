pragma solidity ^0.5.4;
import "./storage/EternalStorage.sol";
import "./libraries/Ownable.sol";

contract ECSAdmin is Ownable {
    EternalStorage private _eternalStorage;

    string private _NFT_FACTORY = "NFT-FACTORY";
    string private _TREE_FACTORY = "TREE-FACTORY";
    string private _IDENTITY_FACTORY = "IDENTITY-FACTORY";

    constructor (address _eternalStorageAddress) public {
        _eternalStorage = EternalStorage(_eternalStorageAddress);
    }

    function setFactory(bytes32 _key, address _factory) public onlyOwner {
        _eternalStorage.set(_key, _factory);
    }
    
    function setFactory(string memory _key, address _factory) public onlyOwner {
        bytes32 factoryKey = keccak256(abi.encode(_key));
        _eternalStorage.set(factoryKey, _factory);
    }

    function getFactory(bytes32 _key) public view returns (address) {
        return _eternalStorage.getAddressValue(_key);
    }
}
