---
eip:
title: Token Interaction Standard
description: A standard action messaging protol for interactions on and between NFTs
author: Alexi (@0xalxi)
discussions-to:
type: Standards Track
category: ERC
status: Draft
created: 2021-4-18
---

## Simple Summary

A standard messaging protocol for interactive tokens.

## Abstract

This standard defines a broadly applicable action messaging protocol for the transmission of arbitrary, user-initiated actions between contracts and tokens. Shared state contracts provide arbitration and logging of the action process.

## Motivation

Tokenized item standards such as [ERC-721](./eip-721.md) and [ERC-1155](./eip-1155.md) serve as the objects of the Ethereum computing environment. The emerging metaverse games are processes that run on these objects. A standard action messaging protocol will allow these game processes to be developed in the same open, Ethereum-native way as the objects they run on.

The messaging protocol outlined defines how an action is initiated and transmitted between tokens and shared state environments. It is paired with a common interface for defining functionality that allows off-chain services to aggregate and query supported contracts for interoperability. Clients can use this common protocol to interact with a network of interactive token contracts.

### Benefits
1. Make interactive token contracts discoverable and usable by metaverse/game/bridge applications
2. Allow for generalized action UIs for users to commit actions with/on their tokens
3. Provide a simple solution for developers to make dynamic NFTs and other tokens
4. Promote decentralized, collaborative game building

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119.

```solidity
pragma solidity ^0.8.0;

/// @title ERC-xxxx Token Interaction Standard
/// @dev See https://eips.ethereum.org/EIPS/eip-xxx
interface IERCxxxxSender {
    /// @notice Send an action to the target address
    /// @dev The action's `fromContract` is automatically set to `address(this)`,
    /// and the `from` parameter is set to `msg.sender`.
    /// @param action The action to send
    function sendAction(Action memory action) external payable;

    /// @notice Check if an action is valid based on its hash and nonce
    /// @dev When an action passes through all three possible contracts
    /// (`fromContract`, `to`, and `state`) the `state` contract validates the
    /// action with the initating `fromContract` using a nonced action hash.
    /// This hash is calculated and saved to storage on the `fromContract` before
    /// action handling is initiated. The `state` contract calculates the hash
    /// and verifies it and nonce with the `fromContract`.
    /// @param _hash The hash to validate
    /// @param _nonce The nonce to validate
    function isValid(uint256 _hash, uint256 _nonce) external returns (bool);

    /// @notice Retrieve list of actions that can be sent.
    /// @dev Intended for use by off-chain applications to query compatible contracts.
    function sendableActions() external view returns (bytes4[] memory);

    /// @notice Change or reaffirm the approved address for an action
    /// @dev The zero address indicates there is no approved address.
    ///  Throws unless `msg.sender` is the `_account`, or an authorized
    ///  operator of the `_account`.
    /// @param _account The account of the account-action pair to approve
    /// @param _action The action of the account-action pair to approve
    /// @param _approved The new approved account-action controller
    function approveForAction(
        address _account,
        bytes4 _action,
        address _approved
    ) external returns (bool);

    /// @notice Enable or disable approval for a third party ("operator") to conduct
    ///  all actions on behalf of `msg.sender`
    /// @dev Emits the ApprovalForAll event. The contract MUST allow
    ///  multiple operators per owner.
    /// @param _operator Address to add to the set of authorized operators
    /// @param _approved True if the operator is approved, false to revoke approval
    function setApprovalForAllActions(address _operator, bool _approved)
        external;

    /// @notice Get the approved address for an account-action pair
    /// @dev Throws if `_tokenId` is not a valid NFT.
    /// @param _account The account of the account-action to find the approved address for
    /// @param _action The action of the account-action to find the approved address for
    /// @return The approved address for this account-action, or the zero address if
    ///  there is none
    function getApprovedForAction(address _account, bytes4 _action)
        external
        view
        returns (address);

    /// @notice Query if an address is an authorized operator for another address
    /// @param _account The address on whose behalf actions are performed
    /// @param _operator The address that acts on behalf of the account
    /// @return True if `_operator` is an approved operator for `_account`, false otherwise
    function isApprovedForAllActions(address _account, address _operator)
        external
        view
        returns (bool);

    /// @dev This emits when an action is sent (`sendAction()`)
    event SendAction(
        bytes4 indexed name,
        address _from,
        address indexed _fromContract,
        uint256 _tokenId,
        address indexed _to,
        uint256 _toTokenId,
        address _state,
        bytes _data
    );

    /// @dev This emits when the approved address for an account-action pair
    ///  is changed or reaffirmed. The zero address indicates there is no
    ///  approved address.
    event ApprovalForAction(
        address indexed _account,
        bytes4 indexed _action,
        address indexed _approved
    );

    /// @dev This emits when an operator is enabled or disabled for an account.
    ///  The operator can conduct all actions on behalf of the account.
    event ApprovalForAllActions(
        address indexed _account,
        address indexed _operator,
        bool _approved
    );
}

interface IERCxxxxReceiver {
    /// @notice Handle an action
    /// @dev Both the `to` contract and `state` contract are called via
    /// `onActionReceived()`.
    /// @param action The action to handle
    function onActionReceived(Action calldata action, uint256 _nonce)
        external
        payable;

    /// @notice Retrieve list of actions that can be received.
    /// @dev Intended for use by off-chain applications to query compatible contracts.
    function receivableActions() external view returns (bytes4[] memory);

    /// @dev This emits when a valid action is received.
    event ActionReceived(
        bytes4 indexed name,
        address _from,
        address indexed _fromContract,
        uint256 _tokenId,
        address indexed _to,
        uint256 _toTokenId,
        address _state,
        bytes _data
    );
}

/// @param _address The address of the interactive object
/// @param tokenId The token that is interacting (optional)
struct ActionObject {
    address _address;
    uint256 _tokenId;
}

/// @param name The name of the action
/// @param user The address of the sender
/// @param from The initiating object
/// @param to The receiving object
/// @param state The state contract
/// @param data Additional data with no specified format
struct Action {
    bytes4 selector;
    address user;
    ActionObject from;
    ActionObject to;
    address state;
    bytes data;
}

```

### Extensions

#### Action Proxies

Action proxies can be used to support backwards compatibility with non-upgradeable contracts, and potentially for cross-chain action bridging.

```solidity
pragma solidity ^0.8.0;

interface IProxyRegistry {
    function register(address _contract, address _proxy) external;
    
    function deregister(address _contract) external;

    function proxy(address _contract)
        external
        view
        returns (address);

    function reverseProxy(address _proxy)
        external
        view
        returns (address);
}
```

#### Controllable

Users of this standard may want to allow trusted contracts to control the action process to provide security guarantees, and support action bridging. Controllers step through the action chain, calling each contract individually in sequence.

Contracts that support Controllers SHOULD ignore require/revert statements related to action verification, and MUST NOT pass the action to the next contract in the chain.

```solidity
pragma solidity ^0.8.0;

interface IControllable {
    function approveController(address sender, string memory action)
        external
        returns (bool);

    function revokeController(address sender, string memory action)
        external
        returns (bool);

    function isApprovedController(address sender, string memory action)
        external
        view
        returns (bool);
}
```

## Rationale

There are many proposed uses for interactions with and between tokenized assets. Projects that are developing or have already developed such features include fully on-chain games like Realms' cross-collection Quests and the fighting game nFight, and partially on-chain games like Worldwide Webb and Axie Infinity. It is critical in each of these cases that users are able to commit actions on and across tokenized assets. Regardless of the nature of these actions, the ecosystem will be stronger if we have a standardized interface that allows for asset-defined action handling, open interaction systems, and cross-functional bridges.

### Validation

Validation of the initiating contract via a hash of the action data was satisfactory to nearly everyone surveyed and was the most gas efficient verification solution explored. We recognize that this solution does not allow the receiving and state contracts to validate the initiating `user` account beyond using `tx.origin`, which is vulnerable to phishing attacks.

We considered using a signed message to validate user-intiation, but this approach had two major drawbacks:

1. **UX** users would be required to perform two steps to commit each action (sign the message, and send the transaction)
2. **Gas** performing signature verification is computationally intensive

Most importantly, the consensus among the developers surveyed is that strict user validation is not necessary because the concern is only that malicious initiating contracts will phish users to commit actions *with* the malicious contract's assets. **This protocol treats the initiating contract's token as the prime mover, not the user.** Anyone can tweet at Bill Gates. Any token can send an action to another token. Which actions are accepted, and how they are handled is left up to the contracts. High-value actions can be reputation-gated via state contracts, or access-gated with allow/disallow-lists. (`Controllable`)[#controllable] contracts can also be used via trusted controllers as an alternative to action chaining.

*Alternatives considered: action transmitted as a signed message, action saved to reusable storage slot on initiating contract*

### State Contracts

Moving state logic into dedicated, parameterized contracts makes state an action primitive and prevents state management from being obscured within the contracts. Specifically, it allows users to decide which "environment" to commit the action in, and allows the initiating and receiving contracts to share state data without requiring them to communicate.

The specifics of state contract interfaces are outside the scope of this standard, and are intended to be purpose-built for unique interactive environments.

### Action Strings

Actions are identified with arbitrary strings. Strings are easy to use because they are human-readable. The trade-off compared with an action ID registry model is in space and gas efficiency, and strict uniqueness.

### Gas and Complexity (regarding action chaining)

Action handling within each contract can be arbitrarily complex, and there is no way to eliminate the possibility that certain contract interactions will run out of gas. However, develoeprs SHOULD make every effort to minimize gas usage in their action handler methods, and avoid the use of for-loops.

*Alternatives considered: multi-request action chains that push-pull from one contract to the next.*

## Backwards Compatibility

Non-upgradeable, already deployed token contracts will not be compatible with this standard unless a proxy registry extension is used.

## Test Cases

Test cases are include in `../assets/eip-####/`.

## Reference Implementation

Implementations for both standard contracts and EIP-2535 Diamonds are included in `../assets/eip-####/`.

## Security Considerations

The core security consideration of this protocol is action validation. Actions are passed from one contract to another, meaning it is not possible for the receiving contract to natively verify that the caller of the initiating contract matches the `action.from` address. One of the most important contributions of this protocol is that it provides an alternative to using signed messages, which require users to perform two operations for every action committed.

As discussed in [Validation](#validation), this is viable because the initiating contract / token is treated as the prime mover, not the user.

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
