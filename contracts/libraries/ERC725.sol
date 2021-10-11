pragma solidity ^0.5.4;
import "./Pausable.sol";
import "./ERC165.sol";

/// @title ERC725
/// @author Mircea Pasoi
/// @notice Abstract contract for ERC725

contract ERC725 is ERC165 {
    
     /*
     *     bytes4(keccak256('getKey(bytes32)')) == 0x12aaac70
     *     bytes4(keccak256('keyHasPurpose(bytes32,uint256)')) == 0xd202158d
     *     bytes4(keccak256('getKeysByPurpose(uint256)')) == 0x9010f726
     *     bytes4(keccak256('addKey(bytes32,uint256,uint256)')) == 0x1d381240
     *     bytes4(keccak256('removeKey(bytes32,uint256)')) == 0x53d413c5
     *     bytes4(keccak256('execute(address,uint256,bytes)')) == 0xb61d27f6
     *     bytes4(keccak256('approve(uint256,bool)')) == 0x747442d3
     *     bytes4(keccak256('changeKeysRequired(uint256,uint256)')) == 0xcf50f15f
     *     bytes4(keccak256('getKeysRequired(uint256)')) == 0xefa62498
     *    
     */
    bytes4 private constant _INTERFACE_ID_ERC725 = 0xfccbffbc;
    //_registerInterface(_INTERFACE_ID_ERC721);
    /// @dev Constructor that adds ERC725 as a supported interface
    constructor() internal {
       _registerInterface(_INTERFACE_ID_ERC725);
    }

    /// @dev ID for ERC165 pseudo-introspection
    /// @return ID for ERC725 interface
    // solhint-disable-next-line func-name-mixedcase
    // function ERC725ID() public pure returns (bytes4) {
    //     return (
    //         this.getKey.selector ^ this.keyHasPurpose.selector ^
    //         this.getKeysByPurpose.selector ^
    //         this.addKey.selector ^ this.removeKey.selector ^
    //         this.execute.selector ^ this.approve.selector ^
    //         this.changeKeysRequired.selector ^ this.getKeysRequired.selector
    //     );
    // }

    // Purpose
    // 1: MANAGEMENT keys, which can manage the identity
    uint256 public constant MANAGEMENT_KEY = 1;
    // 2: EXECUTION keys, which perform actions in this identities name (signing, logins, transactions, etc.)
    uint256 public constant EXECUTION_KEY = 2;
    // 3: CLAIM signer keys, used to sign claims on other identities which need to be revokable.
    uint256 public constant CLAIM_SIGNER_KEY = 3;
    // 4: ENCRYPTION keys, used to encrypt data e.g. hold in claims.
    uint256 public constant ENCRYPTION_KEY = 4;
    // 5: DIARY_KEY keys, which can manage the identity
    uint256 public constant DIARY_KEY = 5;
    // 6: ACTION_KEY keys, which can manage the identity
    uint256 public constant ACTION_KEY = 6;
    // 7: EXPECIAL_KEY keys, which can manage the identity
    uint256 public constant ESPECIAL_KEY = 7;

    // KeyType
    uint256 public constant ECDSA_TYPE = 1;
    // https://medium.com/@alexberegszaszi/lets-bring-the-70s-to-ethereum-48daa16a4b51
    uint256 public constant RSA_TYPE = 2;

    // Events
    event KeyAdded(bytes32 indexed key, uint256 indexed purpose, uint256 indexed keyType);
    event KeyRemoved(bytes32 indexed key, uint256 indexed purpose, uint256 indexed keyType);
    event ExecutionRequested(uint256 indexed executionId, address indexed to, uint256 indexed value, bytes data);
    event Executed(uint256 indexed executionId, address indexed to, uint256 indexed value, bytes data);
    event Approved(uint256 indexed executionId, bool approved);
    event KeysRequiredChanged(uint256 indexed purpose, uint256 indexed number);
    //  Extra event, not part of the standard
    event ExecutionFailed(uint256 indexed executionId, address indexed to, uint256 indexed value, bytes data);

    // Functions
    function getKey(bytes32 _key) public view returns(uint256[] memory purposes, uint256 keyType, bytes32 key);
    function keyHasPurpose(bytes32 _key, uint256 purpose) public view returns(bool exists);
    function getKeysByPurpose(uint256 _purpose) public view returns(bytes32[] memory keys);
    function addKey(bytes32 _key, uint256 _purpose, uint256 _keyType) public returns (bool success);
    function removeKey(bytes32 _key, uint256 _purpose) public returns (bool success);
    function changeKeysRequired(uint256 purpose, uint256 number) external;
    function getKeysRequired(uint256 purpose) public view returns(uint256);
    function execute(address _to, uint256 _value, bytes memory _data) public returns (uint256 executionId);
    function approve(uint256 _id, bool _approve) public returns (bool success);
}

