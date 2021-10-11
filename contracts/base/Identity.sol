pragma solidity ^0.5.4;
import "../libraries/ClaimManager.sol";
import "../libraries/KeyManager.sol";

contract Identity is KeyManager, ClaimManager {
    string public globalIdentifierNumber;
    
    constructor(string memory _globalIdentifierNumber) public {
        globalIdentifierNumber = _globalIdentifierNumber;
    }
}
