pragma solidity ^0.5.4;

contract IPartialMerkleTreeImplementation {
    event DataInserted (
        string Action,
        string From,
        string To,
        string Description,
        string Date,
        address Creator,
        bytes Signature
    );

    function insert(string memory _action, string memory _from, string memory _to, string memory _description, string memory _date, bytes memory _signature) public;
}
