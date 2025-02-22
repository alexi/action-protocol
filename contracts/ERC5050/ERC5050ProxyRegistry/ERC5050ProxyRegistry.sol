// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

/*********************************************************************************************\
* Author: Hypervisor <chitch@alxi.nl> (https://twitter.com/0xalxi)
* EIP-5050 Interactive NFTs with Modular Environments: https://eips.ethereum.org/EIPS/eip-5050
/*********************************************************************************************/


/// @dev The interface a contract MUST implement if it is the implementer of
/// some (other) interface for any address other than itself.
interface ERC5050ProxyImplementerInterface {
    /// @notice Indicates whether the contract implements the interface 'interfaceHash' for the address 'addr' or not.
    /// @param interfaceHash keccak256 hash of the name of the interface
    /// @param addr Address for which the contract will implement the interface
    /// @return ERC5050_ACCEPT_MAGIC only if the contract implements 'interfaceHash' for the address 'addr'.
    function canImplementInterfaceForAddress(bytes4 interfaceHash, address addr) external view returns(bytes32);
}

/// @title ERC5050 Proxy Registry Contract (owner-manageable ERC5050Proxy Contract)
/// @notice This contract is the official implementation of the ERC5050 Proxy Registry.
/// @notice For more details, see https://eips.ethereum.org/EIPS/eip-5050
contract ERC5050ProxyRegistry {
    /// @notice Magic value which is returned if a contract implements an interface on behalf of some other address.
    bytes32 constant internal ERC5050_ACCEPT_MAGIC = keccak256(abi.encodePacked("ERC5050_ACCEPT_MAGIC"));

    /// @notice mapping from addresses and interface hashes to their implementers.
    mapping(address => mapping(bytes4 => address)) internal interfaces;
    /// @notice mapping from addresses to their manager.
    mapping(address => address) internal managers;
    /// @notice mapping from contract addresses to boolean flag indicating `owner()` is disallowed manager priveleges.
    mapping(address => bool) internal disallowedOwnerManagers;

    /// @notice Indicates a contract is the 'implementer' of 'interfaceHash' for 'addr'.
    event InterfaceImplementerSet(address indexed addr, bytes32 indexed interfaceHash, address indexed implementer);
    /// @notice Indicates 'newManager' is the address of the new manager for 'addr'.
    event ManagerChanged(address indexed addr, address indexed newManager);

    /// @notice Query if an address implements an interface and through which contract.
    /// @param _addr Address being queried for the implementer of an interface.
    /// (If '_addr' is the zero address then 'msg.sender' is assumed.)
    /// @param _interfaceHash Keccak256 hash of the name of the interface as a string.
    /// E.g., 'web3.utils.keccak256("ERC777TokensRecipient")' for the 'ERC777TokensRecipient' interface.
    /// @return The address of the contract which implements the interface '_interfaceHash' for '_addr'
    /// or '0' if '_addr' did not register an implementer for this interface.
    function getInterfaceImplementer(address _addr, bytes4 _interfaceHash) external view returns (address) {
        address addr = _addr == address(0) ? msg.sender : _addr;
        if(interfaces[addr][_interfaceHash] != address(0)) {
            return interfaces[addr][_interfaceHash];
        }
        return _addr;
    }

    /// @notice Sets the contract which implements a specific interface for an address.
    /// Only the manager defined for that address can set it.
    /// (Each address is the manager for itself until it sets a new manager.)
    /// @param _addr Address for which to set the interface.
    /// (If '_addr' is the zero address then 'msg.sender' is assumed.)
    /// @param _interfaceHash Keccak256 hash of the name of the interface as a string.
    /// E.g., 'web3.utils.keccak256("ERC777TokensRecipient")' for the 'ERC777TokensRecipient' interface.
    /// @param _implementer Contract address implementing '_interfaceHash' for '_addr'.
    function setInterfaceImplementer(address _addr, bytes4 _interfaceHash, address _implementer) external {
        address addr = _addr == address(0) ? msg.sender : _addr;
        require(getManager(addr) == msg.sender || getOwner(_addr) == msg.sender, "Not the manager");

        // require(!isERC165Interface(_interfaceHash), "Must not be an ERC165 hash");
        if (_implementer != address(0) && _implementer != msg.sender) {
            require(
                ERC5050ProxyImplementerInterface(_implementer)
                    .canImplementInterfaceForAddress(_interfaceHash, addr) == ERC5050_ACCEPT_MAGIC,
                "Does not implement the interface"
            );
        }
        interfaces[addr][_interfaceHash] = _implementer;
        emit InterfaceImplementerSet(addr, _interfaceHash, _implementer);
    }

    /// @notice Sets '_newManager' as manager for '_addr'.
    /// The new manager will be able to call 'setInterfaceImplementer' for '_addr'.
    /// @param _addr Address for which to set the new manager.
    /// @param _newManager Address of the new manager for 'addr'. (Pass '0x0' to reset the manager to '_addr'.)
    function setManager(address _addr, address _newManager) external {
        require(getManager(_addr) == msg.sender || getOwner(_addr) == msg.sender, "Not the manager");
        managers[_addr] = _newManager == _addr ? address(0) : _newManager;
        emit ManagerChanged(_addr, _newManager);
    }

    /// @notice Get the manager of an address.
    /// @param _addr Address for which to return the manager.
    /// @return Address of the manager for a given address.
    function getManager(address _addr) public view returns(address) {
        // By default the manager of an address is the same address
        if (managers[_addr] == address(0)) {
            return _addr;
        } else {
            return managers[_addr];
        }
    }
    
    /// @notice Get the owner of an address.
    /// @param _addr Address for which to return the owner.
    /// @return Address of the owner for a given address.
    function getOwner(address _addr) internal view returns (address) {
        if(disallowedOwnerManagers[_addr]) {
            return _addr;
        }
        (bool success, bytes memory returnData) = _addr.staticcall(
            abi.encodeWithSignature("owner()")
        );
        if(success){
            return abi.decode(returnData, (address));
        }
        return _addr;
    }
    
    /// @notice Disallow owner of `msg.sender` from setting manager. Intended to be called
    /// by a contract that implements `owner()` and does not want to allow the owner to set
    /// the manager.
    function disallowOwner() external {
        disallowedOwnerManagers[msg.sender] = true;
    }
}