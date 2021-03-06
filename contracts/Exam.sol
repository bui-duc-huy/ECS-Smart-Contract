pragma solidity ^0.5.4;
import "./interfaces/factories/INFTFactory.sol";
import "./storage/EternalStorage.sol";
import "./libraries/String.sol";
import "./interfaces/bases/INFT.sol";
import "./interfaces/factories/ITreeFactory.sol";
import "./interfaces/bases/IPartialMerkleTreeImplementation.sol";
import "./libraries/Ownable.sol";

contract ExamController is  Ownable { 
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

    event ExamCreated (
        string Subject,
        string Class,
        string Time,
        string Description,
        address Creator,
        address NFTAddress
    );

    event JoinExam (address Exam, address Student, uint256 TokenId);

    constructor (address _eternalStorageAddress) public {
        _eternalStorage = EternalStorage(_eternalStorageAddress);
    }

    function _setExamAddress(bytes32 _key, address _exam) private {
        bytes32 hashKey = keccak256(abi.encode(_key, _KEY_TO_EXAM));
        _eternalStorage.set(hashKey, _exam);
    }


    function _createExam(string memory _subject, string memory _class, string memory _time, string memory _description, uint256 _salt) private returns(address) {
        bytes32 factoryKey = keccak256(abi.encode(_NFT_FACTORY));
        INFTFactory nft = INFTFactory(_eternalStorage.getAddressValue(factoryKey));
        address newNft = nft.deploy(_subject, _subject.concat("/").concat(_time), _salt);
        bytes32 examKey = keccak256(abi.encode(_subject, _class, _time, _description));

        _setExamAddress(examKey, newNft);

        return newNft;
    }

    function _createNft(address _examNft, address _receiver, address _treeAddress, string memory _uri, uint256 _id) private returns(uint256) {
        INFT examNft = INFT(_examNft);
        uint256 tokenId = examNft.createNewToken(_uri, _receiver,  _treeAddress, _id);

        return tokenId;
    }

    function _createTree(uint256 _salt) private returns(address) {
        bytes32 factoryKey = keccak256(abi.encode(_TREE_FACTORY));
        ITreeFactory treeFactory = ITreeFactory(_eternalStorage.getAddressValue(factoryKey));
        address newTree = treeFactory.deploy(bytes32(0), _salt);

        return newTree; 
    }

    function _insertEvent(address _tree, string memory _action, string memory _from, string memory _to, string memory _description, string memory _date, address _signer, bytes memory _signature) private {
        IPartialMerkleTreeImplementation tree = IPartialMerkleTreeImplementation(_tree);
        tree.insert(_action, _from, _to, _description, _date, _signer, _signature);
    }

    function createExam(string memory _subject, string memory _class, string memory _time, string memory _description, uint256 _salt) public returns(address) {
        address newNft = _createExam(_subject, _class, _time, _description, _salt);

        emit ExamCreated(_subject, _class, _time, _description, tx.origin, newNft);
    }

    function getExamAddress(bytes32 _key) view public returns(address) {
        bytes32 hashKey = keccak256(abi.encode(_key, _KEY_TO_EXAM));
        return _eternalStorage.getAddressValue(hashKey);
    }

    function getExamAddress(string memory _subject, string memory _class, string memory _time, string memory _description) view public returns(address) {
        bytes32 key = keccak256(abi.encode(_subject, _class, _time, _description));
        return getExamAddress(key);
    }

    function getExamTree(address _examNft, uint256 _tokenId) public view returns(address) {
        INFT examNft = INFT(_examNft);
        return examNft.getTreeOfToken(_tokenId);
    }

    function joinExam(address _examNft, address _student, string memory _action, string memory _from, string memory _to, string memory _description, string memory _date, address _signer, bytes memory _signature, string memory _uri, uint256 _salt) public {
        address treeAddress = _createTree(_salt); 
        uint256 tokenId = _createNft(_examNft, _student, treeAddress, _uri, _salt);

        _insertEvent(treeAddress, _action, _from, _to, _description, _date, _signer, _signature);
        
        emit JoinExam(_examNft, _student, tokenId); 
    }

    function insertEventToExam(address _examNft, uint256 _tokenId, string memory _action, string memory _from, string memory _to, string memory _description, string memory _date, address _signer, bytes memory _signature) public {
        INFT examNft = INFT(_examNft);
        address treeAddress = examNft.getTreeOfToken(_tokenId);

        _insertEvent(treeAddress, _action, _from, _to, _description, _date, _signer, _signature);
    }
}
