pragma solidity ^0.5.4;
import "../interfaces/factories/INFTFactory.sol";
import "../storage/EternalStorage.sol";
import "../libraries/String.sol";

contract ExamController {
    using Strings for string;

    EternalStorage private _eternalStorage;

    string private _NFT_FACTORY = "NFT-FACTORY";
    string private _TREE_FACTORY = "TREE-FACTORY";
    string private _IDENTITY_FACTORY = "IDENTITY-FACTORY";

    string private _KEY_TO_EXAM = "KEY-TO-EXAM";

    event ExamCreated (
        string Subject,
        string Class,
        string Time,
        string Description,
        address Creator,
        address NFTAddress
    );

    constructor (address _eternalStorageAddress) public {
        _eternalStorage = EternalStorage(_eternalStorageAddress);
    }

    function _setExamAddress(bytes32 _key, address _exam) private {
    }

    function _createExam(string memory _subject, string memory _class, string memory _time, string memory _description, uint256 _salt) private {
        bytes32 factoryKey = keccak256(abi.encode(_NFT_FACTORY));
        INFTFactory nft = INFTFactory(_eternalStorage.getAddressValue(factoryKey));
        address newNft = nft.deploy(_subject, _subject.concat("/").concat(_time), _salt);

        bytes32 examKey = keccak256(abi.encode(_subject, _class, _time, _description));

        _setExamAddress(examKey, newNft);

        emit ExamCreated(_subject, _class, _time, _description, tx.origin, newNft);
    }

    function createExam(string memory _subject, string memory _class, string memory _time, string memory _description, uint256 _salt) public {
        _createExam(_subject, _class, _time, _description, _salt);
    }
}
