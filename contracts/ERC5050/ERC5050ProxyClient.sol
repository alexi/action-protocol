// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

/*********************************************************************************************\
* Author: Hypervisor <chitch@alxi.nl> (https://twitter.com/0xalxi)
* EIP-5050 Interactive NFTs with Modular Environments: https://eips.ethereum.org/EIPS/eip-5050
/*********************************************************************************************/

import { IERC5050RegistryClient } from "../interfaces/IERC5050RegistryClient.sol";
import { IERC5050Receiver, IERC5050Sender } from "../interfaces/IERC5050.sol";

contract ERC5050ProxyClient {
    IERC5050RegistryClient proxyRegistry = IERC5050RegistryClient(0x5050f71E270671315B460F5C4C37A82deAE6F77D);
    address internal _proxiedSender;
    address internal _proxiedReceiver;

    function _setProxyRegistry(address _proxyRegistry) internal {
        proxyRegistry = IERC5050RegistryClient(_proxyRegistry);
    }

    function getSenderProxy(address _addr) internal view returns (address) {
        if(_addr == address(0)){
            return _addr;
        }
        
        // Proxy contracts should know the address of the contract they are proxying for, and
        // can skip the read request to the registry.
        if(_proxiedSender == _addr) {
            return address(this);
        }
        if(address(proxyRegistry) == address(0)){
            return _addr;
        }
        return proxyRegistry.getInterfaceImplementer(_addr, type(IERC5050Sender).interfaceId);
    }

    function getReceiverProxy(address _addr) internal view returns (address) {
        if(_addr == address(0)){
            return _addr;
        }
        
        // Proxy contracts should know the address of the contract they are proxying for, and
        // can skip the read request to the registry.
        if(_proxiedReceiver == _addr) {
            return address(this);
        }
        if(address(proxyRegistry) == address(0)){
            return _addr;
        }
        return proxyRegistry.getInterfaceImplementer(_addr, type(IERC5050Receiver).interfaceId);
    }
}
