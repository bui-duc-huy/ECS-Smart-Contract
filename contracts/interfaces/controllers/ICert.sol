pragma solidity ^0.5.4;

contract ICertController {
    event CertCollectionCreated (bytes32 Key, string CertName, string CertSymbol, address Creator, address CertCollectionAddress);

    event CertIssued(address CertCollectionAddress, address Issuer, address Receiver);

    function createCertCollection(bytes32 _key, string memory _certName, string memory _certSymbol, uint256 _salt) public returns(address);

    function createCert(address _certCollection, address _user, string memory _uri, uint256 _salt) public returns(uint256);

    function insertEventToCert(address _examNft, uint256 _tokenId, string memory _action, string memory _from, string memory _to, string memory _description, string memory _date, bytes memory _signature) public;
}
