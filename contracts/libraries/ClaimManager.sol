pragma solidity ^0.5.4;
import "./KeyManager.sol";
import "./ERC735.sol";
import "./Pausable.sol";
import "./ECDSA.sol";
import "./ERC165Query.sol";

/// @title ClaimManager
/// @author Mircea Pasoi
/// @notice Implement functions from ERC735 spec
/// @dev  Key data is stored using KeyStore library. Inheriting ERC725 for the getters

contract ClaimManager is KeyManager, ERC735 {

    mapping (bytes32 => Claim) claims;
    mapping (uint256 => bytes32[]) claimsByType;

    function addClaim(
        uint256 _claimType,
        uint256 _scheme,
        address _issuer,
        bytes memory _signature,
        bytes memory _data,
        string memory _uri
    )
        public
        returns (bytes32 claimRequestId)
    {
        bytes32 claimId = keccak256(abi.encode(_issuer, _claimType));

        if (msg.sender != address(this)) {
          require(keyHasPurpose(keccak256(abi.encode(msg.sender)), 3), "Sender does not have claim signer key");
        }

        if (claims[claimId].issuer != _issuer) {
            claimsByType[_claimType].push(claimId);
        }

        claims[claimId].claimType = _claimType;
        claims[claimId].scheme = _scheme;
        claims[claimId].issuer = _issuer;
        claims[claimId].signature = _signature;
        claims[claimId].data = _data;
        claims[claimId].uri = _uri;

        emit ClaimAdded(
            claimId,
            _claimType,
            _scheme,
            _issuer,
            _signature,
            _data,
            _uri
        );

        return claimId;
    }

    function removeClaim(bytes32 _claimId) public returns (bool success) {
        if (msg.sender != address(this)) {
          require(keyHasPurpose(keccak256(abi.encode(msg.sender)), 3), "Sender does not have claim signer key");
        }

        /* uint index; */
        /* (index, ) = claimsByType[claims[_claimId].claimType].indexOf(_claimId);
        claimsByType[claims[_claimId].claimType].removeByIndex(index); */

        emit ClaimRemoved(
            _claimId,
            claims[_claimId].claimType,
            claims[_claimId].scheme,
            claims[_claimId].issuer,
            claims[_claimId].signature,
            claims[_claimId].data,
            claims[_claimId].uri
        );

        delete claims[_claimId];
        return true;
    }

    function getClaim(bytes32 _claimId)
        public
        view
        returns(
            uint256 claimType,
            uint256 scheme,
            address issuer,
            bytes memory signature,
            bytes memory data,
            string memory uri
        )
    {
        return (
            claims[_claimId].claimType,
            claims[_claimId].scheme,
            claims[_claimId].issuer,
            claims[_claimId].signature,
            claims[_claimId].data,
            claims[_claimId].uri
        );
    }

    function getClaimIdsByType(uint256 _claimType)
        public
        view
        returns(bytes32[] memory claimIds)
    {
        return claimsByType[_claimType];
    }

}
