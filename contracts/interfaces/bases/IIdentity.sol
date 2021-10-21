pragma solidity ^0.5.4;
import "../../libraries/ERC725.sol";

contract IIdentity is ERC725 {
    event SetIdentityNumber(address TrustedIdentity, string IdentityNumber);
    function setIdentityNumber(address _trustedIdentity, string memory _number) public;
}
