pragma solidity ^0.5.4;

library KeyStore {
    struct Key {
        uint256 purpose; //e.g., MANAGEMENT_KEY = 1, EXECUTION_KEY = 2, etc.
        uint256 keyType; // e.g. 1 = ECDSA, 2 = RSA, etc.
        bytes32 key; // for non-hex and long keys, its the Keccak256 hash of the key
    }

    struct Keys {
        mapping (bytes32 => Key) keyData;
        mapping (uint256 => bytes32[]) keysByPurpose;
        uint numKeys;
    }

    /// @dev Find a key + purpose tuple
    /// @param key Key bytes to find
    /// @param purpose Purpose to find
    /// @return `true` if key + purpose tuple if found
    function find(Keys storage self, bytes32 key, uint256 purpose)
        internal
        view
        returns (bool)
    {
        Key memory k = self.keyData[key];
        if (k.key == 0) {
            return false;
        }
        if (k.purpose <= purpose) {
            return true;
        }
        return false;
    }
    

    /// @dev Add a Key
    /// @param key Key bytes to add
    /// @param purpose Purpose to add
    /// @param keyType Key type to add
    function add(Keys storage self, bytes32 key, uint256 purpose, uint256 keyType)
        internal
        
    {
        Key storage k = self.keyData[key];
        k.purpose = purpose;
        if (k.key == 0) {
            k.key = key;
            k.keyType = keyType;
        }
        self.keysByPurpose[purpose].push(key);
        self.numKeys++;
    }

    /// @dev Remove Key
    /// @param key Key bytes to remove
    /// @return Key type of the key that was removed
    function remove(Keys storage self, bytes32 key)
        internal
        returns (uint256 keyType)
    {
        keyType = self.keyData[key].keyType;
        // Delete purpose from keyData
        delete self.keyData[key];
        
        return keyType;
    }
}


/// @title KeyBase
/// @author Mircea Pasoi
/// @notice Abstract contract for ERC725 implementation
/// @dev Key data is stored using KeyStore library

contract KeyBase {
    // Key storage
    using KeyStore for KeyStore.Keys;
    KeyStore.Keys internal allKeys;

    /// @dev Number of keys managed by the contract
    /// @return Unsigned integer number of keys
    function numKeys()
        external
        view
        returns (uint)
    {
        return allKeys.numKeys;
    }

    /// @dev Convert an Ethereum address (20 bytes) to an ERC725 key (32 bytes)
    function addrToKey(address addr)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(addr));
    }
}
