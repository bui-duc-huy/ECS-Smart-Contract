pragma solidity ^0.5.4;
import "./ClaimManager.sol";
import "./ECDSA.sol";

contract ClaimVerifier {
    event ClaimValid(ClaimManager _identity, uint256 claimType);
    event ClaimInvalid(ClaimManager _identity, uint256 claimType);

    function checkClaim(ClaimManager _trustedClaimHolder, ClaimManager _identity, uint256 claimType) public returns (bool claimValid) {
        if (claimIsValid(_trustedClaimHolder, _identity, claimType)) {
            emit ClaimValid(_identity, claimType);
            return true;
        } else {
            emit ClaimInvalid(_identity, claimType);
            return false;
        }
    }


    function claimIsValid(ClaimManager _trustedClaimHolder, ClaimManager _identity, uint256 claimType) public view returns (bool claimValid) {
        uint256 foundClaimType;
        uint256 scheme;
        address issuer;
        bytes memory sig;
        bytes memory data;

        bytes32 claimId = keccak256(abi.encode(_trustedClaimHolder, claimType));
        ( foundClaimType, scheme, issuer, sig, data, ) = _identity.getClaim(claimId);

        bytes32 dataHash = keccak256(abi.encode(_identity, claimType, data));
        bytes32 prefixedHash = keccak256(abi.encode("\x19Ethereum Signed Message:\n32", dataHash));

        address recovered = ECDSA.recover(prefixedHash, sig);
        bytes32 hashedAddr = keccak256(abi.encode(recovered));

        return _trustedClaimHolder.keyHasPurpose(hashedAddr, 3);
    }
}
