pragma solidity ^0.5.4;
import "../storage/EternalStorage.sol";

contract ExamController {
    EternalStorage private _eternalStorage;
    string private _NFT_FACTORY = "NFT-FACTORY";
    string private _TREE_FACTORY = "TREE-FACTORY";
    string private _IDENTITY_FACTORY = "IDENTITY-FACTORY";

    constructor (address _eternalStorageAddress) public {
        _eternalStorage = EternalStorage(_eternalStorageAddress);
    }

}
