pragma solidity ^0.5.4;
import "../libraries/ERC721.sol";
import "../interfaces/bases/INFT.sol";

contract NFT is ERC721, ERC721Enumerable, ERC721Metadata, INFT {
    mapping(uint256 => address) private _treeOfToken;

    constructor (string memory _name, string memory _symbol) public ERC721Metadata(_name, _symbol) {
        emit NewERC721Info(_name, _symbol);
    }

    function _setTreeOfToken(uint256 _tokenId, address _tree) private {
        _treeOfToken[_tokenId] = _tree;
    }

    function tokenOfOwner(address owner) public view returns(uint256[] memory) {
        return _tokensOfOwner(owner);
    }

    function createNewToken(string memory _uri, address _receiver, address _tree) public returns(uint256) {
        uint256 id = totalSupply();
        super._mint(_receiver, id);
        super._setTokenURI(id, _uri);

        string memory _name = name();
        string memory _symbol = symbol();

        _setTreeOfToken(id, _tree);

        emit NewERC721TokenInfo(_name, _symbol, id, _uri, tx.origin, _tree);
        return id;
    }

    function getTreeOfToken(uint256 _tokenId) public returns(address) {
        return _treeOfToken[_tokenId];
    }
    
    function removeAsset(uint256 tokenId) public {
        require(tx.origin == ownerOf(tokenId) || tx.origin == getApproved(tokenId));
        super._burn(tokenId);
        emit RemoveSmallFile(tokenId, ownerOf(tokenId), tx.origin);
    }
}
