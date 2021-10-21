pragma solidity ^0.5.4;
import "../interfaces/factories/INFTFactory.sol";
import "../storage/EternalStorage.sol";
import "../interfaces/bases/INFT.sol";

contract CertController {
    EternalStorage private _eternalStorage;

    string private _NFT_FACTORY = "NFT-FACTORY";
    string private _TREE_FACTORY = "TREE-FACTORY";
    string private _IDENTITY_FACTORY = "IDENTITY-FACTORY";

    string private _KEY_TO_CERT_COLLECTION = "KEY-TO-CERT-COLLECTION";

    constructor (address _eternalStorageAddress) public {
        _eternalStorage = EternalStorage(_eternalStorageAddress);
    }

    function _setCertCollection(bytes32 _key, address _certCollection) private {
        _eternalStorage.set(keccak256(abi.encode(_key, _KEY_TO_CERT_COLLECTION)), _certCollection);
    }

    function _createTree(uint256 _salt) private returns(address) {
        bytes32 factoryKey = keccak256(abi.encode(_TREE_FACTORY));
        ITreeFactory treeFactory = ITreeFactory(_eternalStorage.getAddressValue(factoryKey));
        address newTree = treeFactory.deploy(bytes32(0), _salt);

        return newTree; 
    }

    function _getCertCollection(bytes32 _key) private returns(address certCollection) {
        certCollection = _eternalStorage.getAddressValue(keccak256(abi.encode(_key, _KEY_TO_CERT_COLLECTION)));
    }

    function _createCertCollection(bytes32 _key, string memory _certName, string memory _certSymbol, uint256 _salt) private returns(address) {
        bytes32 factoryKey = keccak256(abi.encode(_NFT_FACTORY));
        INFTFactory nft = INFTFactory(_eternalStorage.getAddressValue(factoryKey));
        address newNft = nft.deploy(_certName, _certSymbol, _salt);

        _setCertCollection(_key, newNft);

        return newNft;
    }

    function _createCert(bytes32 _key, address _user, string memory _uri, uint256 _salt) private return (uint256) {
        address nftAddress = _getCertCollection(_key);
        INFT nft = INFT(nftAddress);

        address tree = _createTree(_salt);
        uint256 tokenId = nft.createNewToken(_uri, tree);

        return tokenId;
    }

    function createCertCollection(bytes _key, string memory _certName, string memory _certSymbol, uint256 _salt) public returns(newNft) {
        newNft = _createCertCollection(_key, _certName, _certSymbol, _salt);
    }

    function createCert(bytes32 _key, address _user, string memory _uri, uint256 _salt) public returns(uint256) {
        uint256 tokenId = _createCert(_key, _user, _uri, _salt);
        return tokenId;
    }

    function insertEventToCert(address _examNft, uint256 _tokenId, string memory _action, string memory _from, string memory _to, string memory _description, string memory _date, bytes memory _signature) private {
        INFT examNft = INFT(_examNft);
        address treeAddress = examNft.getTreeOfToken(_tokenId);

        _insertEvent(treeAddress, _action, _from, _to, _description, _date, _signature);
    }
}
