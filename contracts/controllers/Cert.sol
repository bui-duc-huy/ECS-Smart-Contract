pragma solidity ^0.5.4;
import "../interfaces/factories/INFTFactory.sol";

contract CertController {
    EternalStorage private _eternalStorage;

    string private _NFT_FACTORY = "NFT-FACTORY";
    string private _TREE_FACTORY = "TREE-FACTORY";
    string private _IDENTITY_FACTORY = "IDENTITY-FACTORY";

    constructor (address _eternalStorageAddress) public {
        _eternalStorage = EternalStorage(_eternalStorageAddress);
    }

    function _setCertCollection(bytes32 _key, address _certCollection) private {
    }

    function _createCertCollection(bytes32 _key, string memory _certName, string memory _certSymbol, uint256 _salt) private returns(address) {
        bytes32 factoryKey = keccak256(abi.encode(_NFT_FACTORY));
        INFTFactory nft = INFTFactory(_eternalStorage.getAddressValue(factoryKey));
        address newNft = nft.deploy(_certName, _certSymbold, _salt);

        return newNft;
    }

    function _createCert(bytes32 _key, address _user) private {

    }

}
