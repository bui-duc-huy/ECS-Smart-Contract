pragma solidity ^0.5.4;
import "./interfaces/bases/IIdentity.sol";
import "./libraries/ECDSA.sol";

contract ClaimVerifier {
    event ClaimValid(IIdentity _identity, uint256 claimType);
    event ClaimInvalid(IIdentity _identity, uint256 claimType);

    function checkClaim(IIdentity _trustedIssuer, IIdentity _identity, uint256 _claimType) public returns (bool) {
        if (claimIsValid(_trustedIssuer, _identity, _claimType)) {
            emit ClaimValid(_identity, _claimType);
            return true;
        } else {
            emit ClaimInvalid(_identity, _claimType);
            return false;
        }
    }

    function claimIsValid(IIdentity _trustedIssuer, IIdentity _identity, uint256 _claimType) public returns (bool) {
        uint256 foundClaimType;
        uint256 scheme;
        address issuer;
        bytes memory sig;
        bytes memory data;

        bytes32 claimId = keccak256(abi.encodePacked(_trustedIssuer, _claimType));

        ( foundClaimType, scheme, issuer, sig, data, ) = _identity.getClaim(claimId);
        bytes32 dataHash = keccak256(abi.encodePacked(_identity, _claimType, data));
        bytes32 prefixedHash = ECDSA.toEthSignedMessageHash(dataHash);

        address recovered = ECDSA.recover(prefixedHash, sig);

        bytes32 hashedAddr = keccak256(abi.encode(recovered));

        return _trustedIssuer.keyHasPurpose(hashedAddr, 3);
    }
}
