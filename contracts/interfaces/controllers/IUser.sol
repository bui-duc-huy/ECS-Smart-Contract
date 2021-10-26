pragma solidity ^0.5.4;

contract IUserController {


    function issueClaim(address _trustedIdentity, address _claimHolder, uint256 _claimType, uint256 _schema, address _issuer, bytes memory _signature, bytes memory _data, string memory _uri) public;
    function getUserIdentity(bytes32 _key) public view returns(address identity);
    function mapIdentity(bytes32 _key, address _identity) public;

    function registerIdentity(
        address _trustedIdentity,
        string memory _number,
        bytes32[] memory _initialKeys,
        bytes32[] memory _keys,
        uint256[] memory _purposes,
        address _owner,
        bytes32 _keyHash,
        uint256 _salt
    )
    public;
}
