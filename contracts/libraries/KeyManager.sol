pragma solidity ^0.5.4;
import "./Pausable.sol";
import "./ERC725.sol";

contract KeyManager is PausableI, ERC725 {
	uint256 executionNonce;
	uint256 internal constant OPERATION_CALL = 0;

	struct Execution {
        address to;
        uint256 value;
        bytes data;
        bool approved;
        bool executed;
    }

	mapping (uint256 => Execution) public executions;

	mapping (uint256 => address[]) public approved;
    /// @dev Add key data to the identity if key + purpose tuple doesn't already exist
    /// @param _key Key bytes to add
    /// @param _purpose Purpose to add
    /// @param _keyType Key type to add
    /// @return `true` if key was added, `false` if it already exists
    function addKey(
        bytes32 _key,
        uint256 _purpose,
        uint256 _keyType
    )
        public
        //onlyManagementOrSelf
        whenNotPaused
        returns (bool success)
    {
        if (allKeys.find(_key, _purpose)) {
            return false;
        }
        
        _addKey(_key, _purpose, _keyType);
        return true;
    }

    /// @dev Remove key data from the identity
    /// @param _key Key bytes to remove
    /// @param _purpose Purpose to remove
    /// @return `true` if key was found and removed, `false` if it wasn't found
    function removeKey(
        bytes32 _key,
        uint256 _purpose
    )
        public
        //onlyManagementOrSelf
        whenNotPaused
        returns (bool success)
    {
        if (!allKeys.find(_key, _purpose)) {
            return false;
        }
        uint256 keyType = allKeys.remove(_key, _purpose);
        emit KeyRemoved(_key, _purpose, keyType);
        return true;
    }

    /// @dev Add key data to the identity without checking if it already exists
    /// @param _key Key bytes to add
    /// @param _purpose Purpose to add
    /// @param _keyType Key type to add
    function _addKey(
        bytes32 _key,
        uint256 _purpose,
        uint256 _keyType
    )
        public
    {
        require(getKeysByPurpose(_purpose).length <= getKeysRequired(_purpose));
        allKeys.add(_key, _purpose, _keyType);
        emit KeyAdded(_key, _purpose, _keyType);
    }

	function getKey(
        bytes32 _key
    )
        public
        view
        returns(uint256[] memory purposes, uint256 keyType, bytes32 key)
    {
        KeyStore.Key memory k = allKeys.keyData[_key];
        purposes = k.purposes;
        keyType = k.keyType;
        key = k.key;
    }

    /// @dev Find if a key has is present and has the given purpose
    /// @param _key Key bytes to find
    /// @param purpose Purpose to find
    /// @return Boolean indicating whether the key exists or not
    function keyHasPurpose(
        bytes32 _key,
        uint256 purpose
    )
        public
        view
        returns(bool exists)
    {
        return allKeys.find(_key, purpose);
    }

    /// @dev Find all the keys held by this identity for a given purpose
    /// @param _purpose Purpose to find
    /// @return Array with key bytes for that purpose (empty if none)
    function getKeysByPurpose(uint256 _purpose)
        public
        view
        returns(bytes32[] memory keys)
    {
        return allKeys.keysByPurpose[_purpose];
    }

	function execute(
        uint256 _operation,
        address _to,
        uint256 _value,
        bytes calldata _data
    ) public payable virtual override returns(bytes memory result) {
        // emit event
        emit Executed(_operation, _to, _value, _data);

        uint256 txGas = gasleft() - 2500;

        // CALL
        if (_operation == OPERATION_CALL) {
           result = executeCall(_to, _value, _data, txGas);

            // DELEGATECALL
        } else if (_operation == OPERATION_DELEGATECALL) {
            address currentOwner = owner();
            result = executeDelegateCall(_to, _data, txGas);

            require(owner() == currentOwner, "Delegate call is not allowed to modify the owner!");

            // CREATE
        } else if (_operation == OPERATION_CREATE) {
            address contractAddress = performCreate(_value, _data);
            result = abi.encodePacked(contractAddress);

            // CREATE2
        } else if (_operation == OPERATION_CREATE2) {
            bytes32 salt = BytesLib.toBytes32(_data, _data.length - 32);
            bytes memory data = BytesLib.slice(_data, 0, _data.length - 32);

            address contractAddress = Create2.deploy(_value, salt, data);
            result = abi.encodePacked(contractAddress);

            emit ContractCreated(contractAddress);
    
        } else {
            revert("Wrong operation type");
        }
    }
}
