pragma solidity ^0.5.4;
pragma experimental ABIEncoderV2;
import "./interfaces/factories/INFTFactory.sol";
import "./interfaces/bases/IPartialMerkleTreeImplementation.sol";
import "./interfaces/factories/ITreeFactory.sol";
import "./storage/EternalStorage.sol";
import "./interfaces/bases/INFT.sol";
import "./interfaces/controllers/ICert.sol";

contract CertController is ICertController {
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

    function _createCert(address _certCollection, address _user, string memory _uri, uint256 _salt) private returns (uint256) {
        INFT nft = INFT(_certCollection);

        address tree = _createTree(_salt);
        uint256 tokenId = nft.createNewToken(_uri, _user, tree, _salt);

        return tokenId;
    }

    function _insertEvent(address _tree, string memory _action, string memory _from, string memory _to, string memory _description, string memory _date, bytes memory _signature) private {
        IPartialMerkleTreeImplementation tree = IPartialMerkleTreeImplementation(_tree);
        tree.insert(_action, _from, _to, _description, _date, _signature);
    }

    function createCertCollection(bytes32 _key, string memory _certName, string memory _certSymbol, uint256 _salt) public returns(address) {
        address newNft = _createCertCollection(_key, _certName, _certSymbol, _salt);

        emit CertCollectionCreated(_key, _certName, _certSymbol, tx.origin, newNft);
        return newNft;
    }

    function createCert(address _certCollection, address _user, string memory _uri, uint256 _salt) public returns(uint256) {
        uint256 tokenId = _createCert(_certCollection, _user, _uri, _salt);

        emit CertIssued(_certCollection, tx.origin, _user);
        return tokenId;
    }

    function createManyCert(address _certCollection, address[] memory _users, string[] memory _uris, uint256[] memory _salts) public {
        for(uint i = 0; i < _users.length; i++) {
            createCert(_certCollection, _users[i], _uris[i], _salts[i]);
        }
    }

    function insertEventToCert(address _examNft, uint256 _tokenId, string memory _action, string memory _from, string memory _to, string memory _description, string memory _date, bytes memory _signature) public {
        INFT examNft = INFT(_examNft);
        address treeAddress = examNft.getTreeOfToken(_tokenId);

        _insertEvent(treeAddress, _action, _from, _to, _description, _date, _signature);
    }
}
