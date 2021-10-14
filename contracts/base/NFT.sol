pragma solidity ^0.5.4;
import "../libraries/ERC721.sol";
import "./PartialMerkleTreeImplementation.sol";

contract NFT is ERC721, ERC721Enumerable, ERC721Metadata {
    event NewERC721Info(string Name, string Symbol);
    event NewERC721TokenInfo(string Name, string Symbol, uint256 Id, string Uri, address Creator);
    event RemoveSmallFile(uint256 TokenId, address Owner, address RemovedBy);
    event LinkTokenWithTree(uint256 TokenId, address Tree);
    event CreateNewTree(bytes32 InitalRoot, address Tree);

    mapping(uint256 => address) private _treeOfToken;

    constructor (string memory _name, string memory _symbol, address _eternalStorageAddress) public ERC721Metadata(_name, _symbol) {
        emit NewERC721Info(_name, _symbol);
    }

    function _setTreeOfToken(uint256 _tokenId, address _treeAddress) private {
        _treeOfToken[_tokenId] = _treeAddress;
        
        emit LinkTokenWithTree(_tokenId, _treeAddress);
    }

    function _getBytecode(bytes32 initialRoot) private pure returns (bytes memory) {
        bytes memory bytecode = type(PartialMerkleTreeImplementation).creationCode;

        return abi.encodePacked(bytecode, abi.encode(initialRoot));
    }

    function _deploy(bytes memory code, uint256 salt) private returns (address){
        address addr;
        assembly {
            addr := create2(0, add(code, 0x20), mload(code), salt)
            if iszero(extcodesize(addr)) {
            revert(0, 0)
            }
        }
        return addr;
    }

    function _deployTree(bytes32 _initialRoot, uint256 _salt) private returns (address) {
        bytes memory byteCode = _getBytecode(_initialRoot);
        address tree = _deploy(byteCode, _salt);
        
        emit CreateNewTree(_initialRoot, tree);
        return tree;
    }
    
    function createNewERC721Token(string memory _uri, bytes32 _initialRoot) public returns(uint256) {
        uint256 id = totalSupply();
	    super._mint(tx.origin, id);
	    super._setTokenURI(id, _uri);

        address tree = _deployTree(_initialRoot, id);
        _setTreeOfToken(id, tree);

		string memory _name = name();
		string memory _symbol = symbol();

        emit NewERC721TokenInfo(_name, _symbol, id, _uri, tx.origin);
        return id;
	}
    
    function removeAsset(uint256 tokenId) public {
        require(tx.origin == ownerOf(tokenId) || tx.origin == getApproved(tokenId));
        super._burn(tokenId);
        emit RemoveSmallFile(tokenId, ownerOf(tokenId), tx.origin);
    }
}
