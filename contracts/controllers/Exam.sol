pragma solidity ^0.5.4;
import "../interfaces/factories/INFTFactory.sol";
import "../storage/EternalStorage.sol";
import "../libraries/String.sol";
import "../interfaces/bases/INFT.sol";
import "../interfaces/factories/ITreeFactory.sol";
import "../interfaces/bases/IPartialMerkleTreeImplementation.sol";

contract ExamController { 
    using Strings for string;

    EternalStorage private _eternalStorage;

    INFTFactory private _nftFactory;
    ITreeFactory private _treeFactory;

    string private _NFT_FACTORY = "NFT-FACTORY";
    string private _TREE_FACTORY = "TREE-FACTORY";
    string private _IDENTITY_FACTORY = "IDENTITY-FACTORY";

    string private _KEY_TO_EXAM = "KEY-TO-EXAM";
    string private _KEY_TO_EXAM_ITEM = "KEY-TO-EXAM-ITEM";
    string private _KEY_TO_TOKEN_ID = "KEY-TO-TOKEN-ID";

    mapping (bytes32 => address) private _contest;

    event ExamCreated (
        string Subject,
        string Class,
        string Time,
        string Description,
        address Creator,
        address NFTAddress
    );

    constructor (address _nftFactoryAddress) public {
    }

    function _setExamAddress(bytes32 _key, address _exam) private {
        bytes32 hashKey = keccak256(abi.encode(_key, _KEY_TO_EXAM));
        _eternalStorage.set(hashKey, _exam);
    }

    function _getExamAddress(bytes32 _key) view private returns(address) {
        bytes32 hashKey = keccak256(abi.encode(_key, _KEY_TO_EXAM));
        return _eternalStorage.getAddressValue(hashKey);
    }

    function _createExam(string memory _subject, string memory _class, string memory _time, string memory _description, uint256 _salt) private {
        bytes32 factoryKey = keccak256(abi.encode(_NFT_FACTORY));
        INFTFactory nft = INFTFactory(_eternalStorage.getAddressValue(factoryKey));
        address newNft = nft.deploy(_subject, _subject.concat("/").concat(_time), _salt);
        bytes32 examKey = keccak256(abi.encode(_subject, _class, _time, _description));

        _setExamAddress(examKey, newNft);

        emit ExamCreated(_subject, _class, _time, _description, tx.origin, newNft);
    }

    function _createNft(address _examNft, address _treeAddress, string memory _uri) private returns(uint256) {
        INFT examNft = INFT(_examNft);
        uint256 tokenId = examNft.createNewToken(_uri, _treeAddress);

        return tokenId;
    }

    function _createTree(uint256 _salt) private returns(address) {
        bytes32 factoryKey = keccak256(abi.encode(_TREE_FACTORY));
        ITreeFactory treeFactory = ITreeFactory(_eternalStorage.getAddressValue(factoryKey));
        address newTree = treeFactory.deploy(bytes32(0), _salt);

        return newTree; 
    }

    function _insertEvent(address _tree, string memory _action, string memory _from, string memory _to, string memory _description, string memory _date, bytes memory _signature) private {
        IPartialMerkleTreeImplementation tree = IPartialMerkleTreeImplementation(_tree);
        tree.insert(_action, _from, _to, _description, _date, _signature);
    }

    function createExam(string memory _subject, string memory _class, string memory _time, string memory _description, uint256 _salt) public {
        _createExam(_subject, _class, _time, _description, _salt);
    }

    function getExamAddress(string memory _subject, string memory _class, string memory _time, string memory _description) public returns(address) {
        bytes32 key = keccak256(abi.encode(_subject, _class, _time, _description));
        return _getExamAddress(key);
    }

    function getExamTree(address _examNft, uint256 _tokenId) public returns(address) {
        INFT examNft = INFT(_examNft);
        return examNft.getTreeOfToken(_tokenId);
    }

    function joinExam(address _examNft, string memory _action, string memory _from, string memory _to, string memory _description, string memory _date, bytes memory _signature, string memory _uri, uint256 _salt) public {
        address treeAddress = _createTree(_salt); 
        uint256 tokenId = _createNft(_examNft, treeAddress, _uri);

        _insertEvent(treeAddress, _action, _from, _to, _description, _date, _signature);
    }

    function insertEvent(address _examNft, uint256 _tokenId, string memory _action, string memory _from, string memory _to, string memory _description, string memory _date, bytes memory _signature) private {
        INFT examNft = INFT(_examNft);
        address treeAddress = examNft.getTreeOfToken(_tokenId);

        _insertEvent(treeAddress, _action, _from, _to, _description, _date, _signature);
    }
}
