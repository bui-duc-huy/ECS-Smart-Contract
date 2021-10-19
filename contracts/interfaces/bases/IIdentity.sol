pragma solidity ^0.5.4;

contract IIdentity {
    event SetIdentityNumber(address TrustedIdentity, string IdentityNumber);
    function setIdentityNumber(address _trustedIdentity, string memory _number) public;
}
