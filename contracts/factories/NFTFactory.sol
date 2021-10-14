pragma solidity ^0.5.4;
import "../bases/NFT.sol";

contract NFTFactory {
    event NFTCreated(address NewERC721Address, address Creator);

    function _getBytecode(string memory _name, string memory _symbol) private pure returns (bytes memory) {
        bytes memory bytecode = type(NFT).creationCode;

        return abi.encodePacked(bytecode, abi.encode(_name, _symbol));
    }

    function _deploy(bytes memory code, uint256 salt) private returns (address){
        address addr;
        assembly {
            addr := create2(0, add(code, 0x20), mload(code), salt)
            if iszero(extcodesize(addr)) {
            revert(0, 0)
            }
        }
        return addr;
    }

    function deploy(string memory _name, string memory _symbol, uint _salt) public returns (address) {
        bytes memory bytecode = _getBytecode(_name, _symbol);

        address nft = _deploy(bytecode, _salt);

        emit NFTCreated(nft, tx.origin);
        return nft;
    }

    function getAddress(string memory _name, string memory _symbol, uint _salt) public view returns (address) {
        bytes memory bytecode = _getBytecode(_name, _symbol);

        bytes32 hash = keccak256(abi.encodePacked(bytes1(0xff), address(this), _salt, keccak256(bytecode)));

        return address(uint160(uint(hash)));
    }
}
