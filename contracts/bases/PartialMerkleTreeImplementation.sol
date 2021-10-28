pragma solidity ^0.5.4;
import {PartialMerkleTree} from "../libraries/Tree.sol";
import "../libraries/ECDSA.sol";
import "../interfaces/bases/IPartialMerkleTreeImplementation.sol";

contract PartialMerkleTreeImplementation is IPartialMerkleTreeImplementation {
    using PartialMerkleTree for PartialMerkleTree.Tree;
    PartialMerkleTree.Tree tree;

    struct Event {
        string action;
        string from;
        string to;
        string description;
        string date;
        address creator;
        bytes signature;
    }

    mapping (bytes32 => Event) private _events;

    constructor (bytes32 initialRoot) public {
        _initialize(initialRoot);
    }

    function _initialize(bytes32 initialRoot) private {
        tree.initialize(initialRoot);
    }

    function _setEvents(bytes32 _key, string memory _action, string memory _from, string memory _to, string memory _description, string memory _date, address _creator, bytes memory _signature) private {
        _events[_key].action = _action;
        _events[_key].from = _from;
        _events[_key].to = _to;
        _events[_key].description = _description;
        _events[_key].date = _date;
        _events[_key].creator = _creator;
        _events[_key].signature = _signature;
    }

    function getEvent(bytes32 _key) public view returns(string memory action, string memory from , string memory to , string memory description, string memory date, address creator, bytes memory signature) {
        return (
            _events[_key].action,
            _events[_key].from,
            _events[_key].to,
            _events[_key].description,
            _events[_key].date,
            _events[_key].creator,
            _events[_key].signature
        );
    }

    function insert(string memory _action, string memory _from, string memory _to, string memory _description, string memory _date, address _signer, bytes memory _signature) public {
        bytes32 key = keccak256(abi.encodePacked(_action, _from, _to, _description, _date));
        bytes32 message = ECDSA.toEthSignedMessageHash(key);
        address signer = ECDSA.recover(message, _signature);
        require(signer == _signer, "Signature invalid");

        _setEvents(key, _action, _from, _to, _description, _date, _signer, _signature);
        tree.insert(abi.encodePacked(key), _signature);

        emit DataInserted(_action, _from, _to, _description, _date, _signer, _signature);
    }

    function commitBranchOfNonInclusion(bytes memory key, bytes32 potentialSiblingLabel, bytes32 potentialSiblingValue, uint branchMask, bytes32[] memory siblings) public {
        return tree.commitBranchOfNonInclusion(key, potentialSiblingLabel, potentialSiblingValue, branchMask, siblings);
    }

    function get(bytes memory key) public view returns (bytes memory) {
        return tree.get(key);
    }

    function safeGet(bytes memory key) public view returns (bytes memory) {
        return tree.safeGet(key);
    }

    function doesInclude(bytes memory key) public view returns (bool) {
        return tree.doesInclude(key);
    }

    function getValue(bytes32 hash) public view returns (bytes memory) {
        return tree.values[hash];
    }

    function getRootHash() public view returns (bytes32) {
        return tree.getRootHash();
    }

    function getProof(bytes memory key) public view returns (uint branchMask, bytes32[] memory _siblings) {
        return tree.getProof(key);
    }

    function getNonInclusionProof(bytes memory key) public view returns (
        bytes32 leafLabel,
        bytes32 leafNode,
        uint branchMask,
        bytes32[] memory _siblings
    ) {
        return tree.getNonInclusionProof(key);
    }

    function verifyProof(bytes32 rootHash, bytes memory key, bytes memory value, uint branchMask, bytes32[] memory siblings) public pure {
        PartialMerkleTree.verifyProof(rootHash, key, value, branchMask, siblings);
    }

    function verifyNonInclusionProof(bytes32 rootHash, bytes memory key, bytes32 leafLabel, bytes32 leafNode, uint branchMask, bytes32[] memory siblings) public pure {
        PartialMerkleTree.verifyNonInclusionProof(rootHash, key, leafLabel, leafNode, branchMask, siblings);
    }
}
