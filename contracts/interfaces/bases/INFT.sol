pragma solidity ^0.5.4;

contract INFT {
    event NewERC721Info(string Name, string Symbol);
    event NewERC721TokenInfo(string Name, string Symbol, uint256 Id, string Uri, address Creator, address TreeData);
    event RemoveSmallFile(uint256 TokenId, address Owner, address RemovedBy);

    function createNewToken(string memory _uri, address _receiver, address _tree, uint256 _id) public returns(uint256);
    function getTreeOfToken(uint256 _tokenId) public view returns(address);
}
