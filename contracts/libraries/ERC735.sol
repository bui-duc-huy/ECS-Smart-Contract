pragma solidity ^0.5.4;
import './ERC165.sol';
/// @title ERC735
/// @author Mircea Pasoi
/// @notice Abstract contract for ERC735

contract ERC735 is ERC165 {
    
    /*
     *     bytes4(keccak256('getClaim(bytes32)')) == 0xc9100bcb
     *     bytes4(keccak256('getClaimIdsByType(uint256)')) == 0x262b54f5
     *     bytes4(keccak256('addClaim(uint256,uint256,address,bytes,bytes,string)')) == 0xb1a34e0d
     *     bytes4(keccak256('removeClaim(bytes32)')) == 0x4eee424a
     *
     *    
     */
    bytes4 private constant _INTERFACE_ID_ERC735 = 0x10765379;
    //_registerInterface(_INTERFACE_ID_ERC721);
    /// @dev Constructor that adds ERC735 as a supported interface
    constructor() internal {
        _registerInterface(_INTERFACE_ID_ERC735);
    }

    /// @dev ID for ERC165 pseudo-introspection
    /// @return ID for ERC725 interface
    // solhint-disable-next-line func-name-mixedcase
    // function ERC735ID() public pure returns (bytes4) {
    //     return (
    //         this.getClaim.selector ^ this.getClaimIdsByType.selector ^
    //         this.addClaim.selector ^ this.removeClaim.selector
    //     );
    // }

    // Topic
    // public constant BIOMETRIC_TOPIC = 1; // you're a person and not a business
    //uint256 public constant RESIDENCE_TOPIC = 2; // you have a physical address or reference point
    //uint256 public constant REGISTRY_TOPIC = 3;
    //uint256 public constant PROFILE_TOPIC = 4; //  social media profiles, blogs, etc.
    //uint256 public constant LABEL_TOPIC = 5; //  real name, business name, nick name, brand name, alias, etc.

    // Scheme
    uint256 public constant ECDSA_SCHEME = 1;
    // https://medium.com/@alexberegszaszi/lets-bring-the-70s-to-ethereum-48daa16a4b51
    uint256 public constant RSA_SCHEME = 2;
    // 3 is contract verification, where the data will be call data, and the issuer a contract address to call
    uint256 public constant CONTRACT_SCHEME = 3;

    // Events
    event ClaimRequested(uint256 indexed claimRequestId, uint256 indexed topic, uint256 scheme, address indexed issuer, bytes signature, bytes data, string uri);
    event ClaimAdded(bytes32 indexed claimId, uint256 indexed topic, uint256 scheme, address indexed issuer, bytes signature, bytes data, string uri);
    event ClaimRemoved(bytes32 indexed claimId, uint256 indexed topic, uint256 scheme, address indexed issuer, bytes signature, bytes data, string uri);
    event ClaimChanged(bytes32 indexed claimId, uint256 indexed topic, uint256 scheme, address indexed issuer, bytes signature, bytes data, string uri);

    // Functions
    function getClaim(bytes32 _claimId) public view returns(uint256 topic, uint256 scheme, address issuer, bytes memory signature, bytes memory data, string memory uri);
    function getClaimIdsByType(uint256 _topic) public view returns(bytes32[] memory claimIds);
    function addClaim(uint256 _topic, uint256 _scheme, address issuer, bytes memory _signature, bytes memory _data, string memory _uri) public returns (uint256 claimRequestId);
    function removeClaim(bytes32 _claimId) public returns (bool success);
}
