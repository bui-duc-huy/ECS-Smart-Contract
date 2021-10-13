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
        whenNotPaused
        returns (bool success)
    {
        if (allKeys.find(_key, _purpose)) {
            return false;
        }

        if (msg.sender != address(this)) {
            require(keyHasPurpose(keccak256(abi.encode(msg.sender)), 1), "Sender does not have management key");
        }
        
        _addKey(_key, _purpose, _keyType);
        return true;
    }

    /// @dev Remove key data from the identity
    /// @param _key Key bytes to remove

    /// @return `true` if key was found and removed, `false` if it wasn't found
    function removeKey(
        bytes32 _key
    )
        public
        whenNotPaused
        returns (bool success)
    {
        if (msg.sender != address(this)) {
            require(keyHasPurpose(keccak256(abi.encode(msg.sender)), 1), "Sender does not have management key");
        }
        
        KeyStore.Key memory k = allKeys.keyData[_key];
        emit KeyRemoved(_key, k.purpose, k.keyType);
        
        allKeys.remove(_key);
        
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
        internal
    {

        allKeys.add(_key, _purpose, _keyType);
        emit KeyAdded(_key, _purpose, _keyType);
    }

    function getKey(
        bytes32 _key
    )
        public
        view
        returns(uint256 purpose, uint256 keyType, bytes32 key)
    {
        KeyStore.Key memory k = allKeys.keyData[_key];
        purpose = k.purpose;
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
        KeyStore.Key memory k = allKeys.keyData[_key];
        return k.purpose <= purpose;
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


    function approve(uint256 _id, bool _approve)
        public
        returns (bool success)
    {
        require(keyHasPurpose(keccak256(abi.encode(msg.sender)), 2), "Sender does not have action key");

        emit Approved(_id, _approve);
        bytes memory tmp;

        if (_approve == true) {
            executions[_id].approved = true;
            (success, tmp) = executions[_id].to.call(executions[_id].data);
            if (success) {
                executions[_id].executed = true;
                emit Executed(
                    _id,
                    executions[_id].to,
                    executions[_id].value,
                    executions[_id].data
                );
                return true;
            } else {
                emit ExecutionFailed(
                    _id,
                    executions[_id].to,
                    executions[_id].value,
                    executions[_id].data
                );
                return false;
            }
        } else {
            executions[_id].approved = false;
        }
        return true;
    }


    function execute(address _to, uint256 _value, bytes memory _data)
        public
        returns (uint256 executionId)
    {
        require(!executions[executionNonce].executed, "Already executed");
        executions[executionNonce].to = _to;
        executions[executionNonce].value = _value;
        executions[executionNonce].data = _data;

        emit ExecutionRequested(executionNonce, _to, _value, _data);

        if (keyHasPurpose(keccak256(abi.encode(msg.sender)), 1) || keyHasPurpose(keccak256(abi.encode(msg.sender)), 2)) {
            approve(executionNonce, true);
        }

        executionNonce++;
        return executionNonce-1;
    }
}
