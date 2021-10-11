pragma solidity ^0.5.4;

library KeyStore {
    struct Key {
        uint256[] purposes; //e.g., MANAGEMENT_KEY = 1, EXECUTION_KEY = 2, etc.
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
        for (uint i = 0; i <= k.purposes.length; i++) {
            if (k.purposes[i] == purpose) {
                return true;
            }
        }
    }

    /// @dev Add a Key
    /// @param key Key bytes to add
    /// @param purpose Purpose to add
    /// @param keyType Key type to add
    function add(Keys storage self, bytes32 key, uint256 purpose, uint256 keyType)
        internal
        
    {
        Key storage k = self.keyData[key];
        k.purposes.push(purpose);
        if (k.key == 0) {
            k.key = key;
            k.keyType = keyType;
        }
        self.keysByPurpose[purpose].push(key);
        self.numKeys++;
    }

    /// @dev Remove Key
    /// @param key Key bytes to remove
    /// @param purpose Purpose to remove
    /// @return Key type of the key that was removed
    function remove(Keys storage self, bytes32 key, uint256 purpose)
        internal
        returns (uint256 keyType)
    {
        keyType = self.keyData[key].keyType;

        uint256[] storage p = self.keyData[key].purposes;
        // Delete purpose from keyData
        for (uint i = 0; i <= p.length; i++) {
            if (p[i] == purpose) {
                p[i] = p[p.length - 1];
                delete p[p.length - 1];
                p.length--;
                self.numKeys--;
                break;
            }
        }
        // No more purposes
        if (p.length == 0) {
            delete self.keyData[key];
        }

        // Delete key from keysByPurpose
        bytes32[] storage k = self.keysByPurpose[purpose];
        for (uint i = 0; i <= k.length; i++) {
            if (k[i] == key) {
                k[i] = k[k.length - 1];
                delete k[k.length - 1];
                k.length--;
            }
        }
    }
}


/// @title KeyBase
/// @author Mircea Pasoi
/// @notice Abstract contract for ERC725 implementation
/// @dev Key data is stored using KeyStore library

contract KeyBase {
    uint256 public constant MANAGEMENT_KEY = 1;

    // For multi-sig
    uint256 public managementRequired = 1;
    uint256 public executionRequired = 1;
    uint256 public diaryRequired = 1;
    uint256 public claimsignerRequired = 1;
    uint256 public encryptionRequired = 1;
    uint256 public actionRequired = 1;
    uint256 public expecialRequired = 1;
    //uint256 public especialRequired = 1;
    
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

    /// @dev Checks if sender is either the identity contract or a MANAGEMENT_KEY
    /// @dev If the multi-sig threshold for MANAGEMENT_KEY if >1, it will throw an error
    /// @return `true` if sender is either identity contract or a MANAGEMENT_KEY
    function _managementOrSelf()
        internal
        view
        returns (bool found)
    {
        if (tx.origin == address(this)) {
            // Identity contract itself
            return true;
        }
        // Only works with 1 key threshold, otherwise need multi-sig
        //require(managementRequired == 1);
        return allKeys.find(addrToKey(tx.origin), MANAGEMENT_KEY);
    }

    /// @dev Modifier that only allows keys of purpose 1, or the identity itself
    modifier onlyManagementOrSelf {
        require(_managementOrSelf());
        _;
    }
}
