//pragma solidity >=0.5.0 <0.6.0;
pragma solidity ^0.5.4;


library D {
    struct Label {
        bytes32 data;
        uint length;
    }

    struct Edge {
        bytes32 header; // variable for partial merkle tree  <email@wanseob.com>
        bytes32 node;
        Label label;
    }

    struct Node {
        Edge[2] children;
    }

    function isEmpty(Edge memory edge) internal pure returns (bool) {
        return (edge.header == bytes32(0) && edge.node == bytes32(0));
    }

    function hasNode(Edge memory edge) internal pure returns (bool) {
        return (edge.node != bytes32(0));
    }
}

library Utils {
    /// Returns a label containing the longest common prefix of `check` and `label`
    /// and a label consisting of the remaining part of `label`.
    function splitCommonPrefix(D.Label memory label, D.Label memory check) internal pure returns (D.Label memory prefix, D.Label memory labelSuffix) {
        return splitAt(label, commonPrefix(check, label));
    }
    /// Splits the label at the given position and returns prefix and suffix,
    /// i.e. prefix.length == pos and prefix.data . suffix.data == l.data.
    function splitAt(D.Label memory l, uint pos) internal pure returns (D.Label memory prefix, D.Label memory suffix) {
        require(pos <= l.length && pos <= 256, "Bad pos");
        prefix.length = pos;
        if (pos == 0) {
            prefix.data = bytes32(0);
        } else {
            prefix.data = l.data & ~bytes32((uint(1) << (256 - pos)) - 1);
        }
        suffix.length = l.length - pos;
        suffix.data = l.data << pos;
    }
    /// Returns the length of the longest common prefix of the two labels.
    function commonPrefix(D.Label memory a, D.Label memory b) internal pure returns (uint prefix) {
        uint length = a.length < b.length ? a.length : b.length;
        // TODO: This could actually use a "highestBitSet" helper
        uint diff = uint(a.data ^ b.data);
        uint mask = 1 << 255;
        for (; prefix < length; prefix++)
        {
            if ((mask & diff) != 0)
                break;
            diff += diff;
        }
    }
    /// Returns the result of removing a prefix of length `prefix` bits from the
    /// given label (i.e. shifting its data to the left).
    function removePrefix(D.Label memory l, uint prefix) internal pure returns (D.Label memory r) {
        require(prefix <= l.length, "Bad lenght");
        r.length = l.length - prefix;
        r.data = l.data << prefix;
    }
    /// Removes the first bit from a label and returns the bit and a
    /// label containing the rest of the label (i.e. shifted to the left).
    function chopFirstBit(D.Label memory l) internal pure returns (uint firstBit, D.Label memory tail) {
        require(l.length > 0, "Empty element");
        return (uint(l.data >> 255), D.Label(l.data << 1, l.length - 1));
    }
    /// Returns the first bit set in the bitfield, where the 0th bit
    /// is the least significant.
    /// Throws if bitfield is zero.
    /// More efficient the smaller the result is.
    function lowestBitSet(uint bitfield) internal pure returns (uint bit) {
        require(bitfield != 0, "Bad bitfield");
        bytes32 bitfieldBytes = bytes32(bitfield);
        // First, find the lowest byte set
        uint byteSet = 0;
        for (; byteSet < 32; byteSet++) {
            if (bitfieldBytes[31 - byteSet] != 0)
                break;
        }
        uint singleByte = uint(uint8(bitfieldBytes[31 - byteSet]));
        uint mask = 1;
        for (bit = 0; bit < 256; bit ++) {
            if ((singleByte & mask) != 0)
                return 8 * byteSet + bit;
            mask += mask;
        }
        assert(false);
        return 0;
    }
    /// Returns the value of the `bit`th bit inside `bitfield`, where
    /// the least significant is the 0th bit.
    function bitSet(uint bitfield, uint bit) internal pure returns (uint) {
        return (bitfield & (uint(1) << bit)) != 0 ? 1 : 0;
    }
}

library PartialMerkleTree {
    using D for D.Edge;

    struct Tree {
        // Mapping of hash of key to value
        mapping(bytes32 => bytes) values;

        // Particia tree nodes (hash to decoded contents)
        mapping(bytes32 => D.Node) nodes;
        // The current root hash, keccak256(node(path_M('')), path_M(''))
        bytes32 root;
        D.Edge rootEdge;
    }

    function initialize(Tree storage tree, bytes32 root) internal {
        require(tree.root == bytes32(0));
        tree.root = root;
    }

    function commitBranch(
        Tree storage tree, 
        bytes memory key, 
        bytes memory value, 
        uint branchMask, 
        bytes32[] memory siblings
    ) internal {
        D.Label memory k = D.Label(keccak256(key), 256);
        D.Edge memory e;
        e.node = keccak256(value);
        tree.values[e.node] = value;
        // e.node(0x083d)
        for (uint i = 0; branchMask != 0; i++) {
            // retrieve edge data with branch mask
            uint bitSet = Utils.lowestBitSet(branchMask);
            branchMask &= ~(uint(1) << bitSet);
            (k, e.label) = Utils.splitAt(k, 255 - bitSet);
            uint bit;
            (bit, e.label) = Utils.chopFirstBit(e.label);

            // find upper node with retrieved edge & sibling
            bytes32[2] memory edgeHashes;
            edgeHashes[bit] = edgeHash(e);
            edgeHashes[1 - bit] = siblings[siblings.length - i - 1];
            bytes32 upperNode = keccak256(abi.encode(edgeHashes[0], edgeHashes[1]));

            // Update sibling information
            D.Node storage parentNode = tree.nodes[upperNode];
            // Put edge
            parentNode.children[bit] = e;
            // Put sibling edge if needed
            if (parentNode.children[1 - bit].isEmpty()) {
                parentNode.children[1 - bit].header = siblings[siblings.length - i - 1];
            }
            // go to upper edge
            e.node = keccak256(abi.encode(edgeHashes[0], edgeHashes[1]));
        }
        e.label = k;
        require(tree.root == edgeHash(e));
        tree.root = edgeHash(e);
        tree.rootEdge = e;
    }

    function commitBranchOfNonInclusion(
        Tree storage tree,
        bytes memory key,
        bytes32 potentialSiblingLabel,
        bytes32 potentialSiblingValue,
        uint branchMask,
        bytes32[] memory siblings
    ) internal {
        D.Label memory k = D.Label(keccak256(key), 256);
        D.Edge memory e;
        // e.node(0x083d)
        for (uint i = 0; branchMask != 0; i++) {
            // retrieve edge data with branch mask
            uint bitSet = Utils.lowestBitSet(branchMask);
            branchMask &= ~(uint(1) << bitSet);
            (k, e.label) = Utils.splitAt(k, 255 - bitSet);
            uint bit;
            (bit, e.label) = Utils.chopFirstBit(e.label);

            if (i == 0) {
                e.label.length = bitSet;
                e.label.data = potentialSiblingLabel;
                e.node = potentialSiblingValue;
            }

            // find upper node with retrieved edge & sibling
            bytes32[2] memory edgeHashes;
            edgeHashes[bit] = edgeHash(e);
            edgeHashes[1 - bit] = siblings[siblings.length - i - 1];
            bytes32 upperNode = keccak256(abi.encode(edgeHashes[0], edgeHashes[1]));

            // Update sibling information
            D.Node storage parentNode = tree.nodes[upperNode];


            // Put edge
            parentNode.children[bit] = e;
            // Put sibling edge if needed
            if (parentNode.children[1 - bit].isEmpty()) {
                parentNode.children[1 - bit].header = siblings[siblings.length - i - 1];
            }
            // go to upper edge
            e.node = keccak256(abi.encode(edgeHashes[0], edgeHashes[1]));
        }
        e.label = k;
        require(tree.root == edgeHash(e));
        tree.root = edgeHash(e);
        tree.rootEdge = e;
    }

    function insert(
        Tree storage tree, 
        bytes memory key, 
        bytes memory value
    ) internal {
        D.Label memory k = D.Label(keccak256(key), 256);
        bytes32 valueHash = keccak256(value);
        tree.values[valueHash] = value;
        // keys.push(key);
        D.Edge memory e;
        if (tree.rootEdge.node == 0 && tree.rootEdge.label.length == 0)
        {
            // Empty Trie
            e.label = k;
            e.node = valueHash;
        }
        else
        {
            e = _insertAtEdge(tree, tree.rootEdge, k, valueHash);
        }
        tree.root = edgeHash(e);
        tree.rootEdge = e;
    }

    function get(Tree storage tree, bytes memory key) internal view returns (bytes memory) {
        return getValue(tree, _findNode(tree, key));
    }

    function safeGet(Tree storage tree, bytes memory key) internal view returns (bytes memory value) {
        bytes32 valueHash = _findNode(tree, key);
        require(valueHash != bytes32(0));
        value = getValue(tree, valueHash);
        require(valueHash == keccak256(value));
    }

    function doesInclude(Tree storage tree, bytes memory key) internal view returns (bool) {
        return doesIncludeHashedKey(tree, keccak256(key));
    }

    function doesIncludeHashedKey(Tree storage tree, bytes32 hashedKey) internal view returns (bool) {
        bytes32 valueHash = _findNodeWithHashedKey(tree, hashedKey);
        return (valueHash != bytes32(0));
    }

    function getValue(Tree storage tree, bytes32 valueHash) internal view returns (bytes memory) {
        return tree.values[valueHash];
    }

    function getRootHash(Tree storage tree) internal view returns (bytes32) {
        return tree.root;
    }

    function edgeHash(D.Edge memory e) internal pure returns (bytes32) {
        require(!e.isEmpty());
        if (e.hasNode()) {
            return keccak256(abi.encode(e.node, e.label.length, e.label.data));
        } else {
            return e.header;
        }
    }

    // Returns the hash of the encoding of a node.
    function hash(D.Node memory n) internal pure returns (bytes32) {
        return keccak256(abi.encode(edgeHash(n.children[0]), edgeHash(n.children[1])));
    }

    // Returns the Merkle-proof for the given key
    // Proof format should be:
    //  - uint branchMask - bitmask with high bits at the positions in the key
    //                    where we have branch nodes (bit in key denotes direction)
    //  - bytes32[] hashes - hashes of sibling edges
    function getProof(Tree storage tree, bytes memory key) internal view returns (uint branchMask, bytes32[] memory _siblings) {
        return getProofWithHashedKey(tree, keccak256(key));
    }

    function getProofWithHashedKey(Tree storage tree, bytes32 hashedKey) internal view returns (uint branchMask, bytes32[] memory _siblings) {
        D.Label memory k = D.Label(hashedKey, 256);
        D.Edge memory e = tree.rootEdge;
        bytes32[256] memory siblings;
        uint length;
        uint numSiblings;
        while (true) {
            D.Label memory prefix;
            D.Label memory suffix;
            (prefix, suffix) = Utils.splitCommonPrefix(k, e.label);
            require(prefix.length == e.label.length);
            if (suffix.length == 0) {
                // Found it
                break;
            }
            length += prefix.length;
            branchMask |= uint(1) << (255 - length);
            length += 1;
            uint head;
            D.Label memory tail;
            (head, tail) = Utils.chopFirstBit(suffix);
            siblings[numSiblings++] = edgeHash(tree.nodes[e.node].children[1 - head]);
            e = tree.nodes[e.node].children[head];
            k = tail;
        }
        if (numSiblings > 0)
        {
            _siblings = new bytes32[](numSiblings);
            for (uint i = 0; i < numSiblings; i++)
                _siblings[i] = siblings[i];
        }
    }

    function getNonInclusionProof(Tree storage tree, bytes memory key) internal view returns (
        bytes32 potentialSiblingLabel,
        bytes32 potentialSiblingValue,
        uint branchMask,
        bytes32[] memory _siblings
    ) {
        return getNonInclusionProofWithHashedKey(tree, keccak256(key));
    }

    function getNonInclusionProofWithHashedKey(Tree storage tree, bytes32 hashedKey) internal view returns (
        bytes32 potentialSiblingLabel,
        bytes32 potentialSiblingValue,
        uint branchMask,
        bytes32[] memory _siblings
    ){
        uint length;
        uint numSiblings;

        // Start from root edge
        D.Label memory label = D.Label(hashedKey, 256);
        D.Edge memory e = tree.rootEdge;
        bytes32[256] memory siblings;

        while (true) {
            // Find at edge
            require(label.length >= e.label.length);
            D.Label memory prefix;
            D.Label memory suffix;
            (prefix, suffix) = Utils.splitCommonPrefix(label, e.label);

            // suffix.length == 0 means that the key exists. Thus the length of the suffix should be not zero
            require(suffix.length != 0);

            if (prefix.length >= e.label.length) {
                // Partial matched, keep finding
                length += prefix.length;
                branchMask |= uint(1) << (255 - length);
                length += 1;
                uint head;
                (head, label) = Utils.chopFirstBit(suffix);
                siblings[numSiblings++] = edgeHash(tree.nodes[e.node].children[1 - head]);
                e = tree.nodes[e.node].children[head];
            } else {
                // Found the potential sibling. Set data to return
                potentialSiblingLabel = e.label.data;
                potentialSiblingValue = e.node;
                break;
            }
        }
        if (numSiblings > 0)
        {
            _siblings = new bytes32[](numSiblings);
            for (uint i = 0; i < numSiblings; i++)
                _siblings[i] = siblings[i];
        }
    }

    function verifyProof(
        bytes32 rootHash, 
        bytes memory key, 
        bytes memory value, 
        uint branchMask, 
        bytes32[] memory siblings
    ) public pure {
        D.Label memory k = D.Label(keccak256(key), 256);
        D.Edge memory e;
        e.node = keccak256(value);
        for (uint i = 0; branchMask != 0; i++) {
            uint bitSet = Utils.lowestBitSet(branchMask);
            branchMask &= ~(uint(1) << bitSet);
            (k, e.label) = Utils.splitAt(k, 255 - bitSet);
            uint bit;
            (bit, e.label) = Utils.chopFirstBit(e.label);
            bytes32[2] memory edgeHashes;
            edgeHashes[bit] = edgeHash(e);
            edgeHashes[1 - bit] = siblings[siblings.length - i - 1];
            e.node = keccak256(abi.encode(edgeHashes[0], edgeHashes[1]));
        }
        e.label = k;
        require(rootHash == edgeHash(e));
    }

    function verifyNonInclusionProof(
        bytes32 rootHash, 
        bytes memory key, 
        bytes32 potentialSiblingLabel, 
        bytes32 potentialSiblingValue, 
        uint branchMask, 
        bytes32[] memory siblings
    ) public pure {
        D.Label memory k = D.Label(keccak256(key), 256);
        D.Edge memory e;
        for (uint i = 0; branchMask != 0; i++) {
            uint bitSet = Utils.lowestBitSet(branchMask);
            branchMask &= ~(uint(1) << bitSet);
            (k, e.label) = Utils.splitAt(k, 255 - bitSet);
            uint bit;
            (bit, e.label) = Utils.chopFirstBit(e.label);
            bytes32[2] memory edgeHashes;
            if (i == 0) {
                e.label.length = bitSet;
                e.label.data = potentialSiblingLabel;
                e.node = potentialSiblingValue;
            }
            edgeHashes[bit] = edgeHash(e);
            edgeHashes[1 - bit] = siblings[siblings.length - i - 1];
            e.node = keccak256(abi.encode(edgeHashes[0], edgeHashes[1]));
        }
        e.label = k;
        require(rootHash == edgeHash(e));
    }

    function newEdge(bytes32 node, D.Label memory label) internal pure returns (D.Edge memory e){
        e.node = node;
        e.label = label;
    }

    function _insertAtNode(Tree storage tree, bytes32 nodeHash, D.Label memory key, bytes32 value) private returns (bytes32) {
        //        require(key.length > 1);
        D.Node memory n = tree.nodes[nodeHash];
        uint head;
        D.Label memory tail;
        (head, tail) = Utils.chopFirstBit(key);
        n.children[head] = _insertAtEdge(tree, n.children[head], tail, value);
        return _replaceNode(tree, nodeHash, n);
    }

    function _insertAtEdge(Tree storage tree, D.Edge memory e, D.Label memory key, bytes32 value) private returns (D.Edge memory) {
        //        require(e.hasNode());
        require(key.length >= e.label.length);
        D.Label memory prefix;
        D.Label memory suffix;
        (prefix, suffix) = Utils.splitCommonPrefix(key, e.label);
        bytes32 newNodeHash;
        if (suffix.length == 0) {
            // Full match with the key, update operation
            newNodeHash = value;
        } else if (prefix.length >= e.label.length && e.hasNode()) {
            // Partial match, just follow the path
            newNodeHash = _insertAtNode(tree, e.node, suffix, value);
        } else {
            // Mismatch, so let us create a new branch node.
            uint head;
            D.Label memory tail;
            (head, tail) = Utils.chopFirstBit(suffix);
            D.Node memory branchNode;
            branchNode.children[head] = newEdge(value, tail);
            branchNode.children[1 - head] = newEdge(e.node, Utils.removePrefix(e.label, prefix.length + 1));
            newNodeHash = _insertNode(tree, branchNode);
        }
        return newEdge(newNodeHash, prefix);
    }

    function _insertNode(Tree storage tree, D.Node memory n) private returns (bytes32 newHash) {
        bytes32 h = hash(n);
        tree.nodes[h].children[0] = n.children[0];
        tree.nodes[h].children[1] = n.children[1];
        return h;
    }

    function _replaceNode(Tree storage tree, bytes32 oldHash, D.Node memory n) private returns (bytes32 newHash) {
        delete tree.nodes[oldHash];
        return _insertNode(tree, n);
    }

    function _findNode(Tree storage tree, bytes memory key) private view returns (bytes32) {
        return _findNodeWithHashedKey(tree, keccak256(key));
    }

    function _findNodeWithHashedKey(Tree storage tree, bytes32 hashedKey) private view returns (bytes32) {
        if (tree.rootEdge.node == 0 && tree.rootEdge.label.length == 0) {
            return 0;
        } else {
            D.Label memory k = D.Label(hashedKey, 256);
            return _findAtEdge(tree, tree.rootEdge, k);
        }
    }

    function _findAtNode(Tree storage tree, bytes32 nodeHash, D.Label memory key) private view returns (bytes32) {
        require(key.length > 1);
        D.Node memory n = tree.nodes[nodeHash];
        uint head;
        D.Label memory tail;
        (head, tail) = Utils.chopFirstBit(key);
        return _findAtEdge(tree, n.children[head], tail);
    }

    function _findAtEdge(Tree storage tree, D.Edge memory e, D.Label memory key) private view returns (bytes32){
        require(key.length >= e.label.length);
        D.Label memory prefix;
        D.Label memory suffix;
        (prefix, suffix) = Utils.splitCommonPrefix(key, e.label);
        if (suffix.length == 0) {
            // Full match with the key, update operation
            return e.node;
        } else if (prefix.length >= e.label.length) {
            // Partial match, just follow the path
            return _findAtNode(tree, e.node, suffix);
        } else {
            // Mismatch, return empty bytes
            return bytes32(0);
        }
    }
}
