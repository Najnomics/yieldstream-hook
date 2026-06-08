// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import {AbstractReactive} from "reactive-lib/abstract-base/AbstractReactive.sol";
import {IReactive} from "reactive-lib/interfaces/IReactive.sol";

contract ReactivePingRSC is IReactive, AbstractReactive {
    error SubscriptionFailed();
    error OnlySubscriptionAdmin();

    uint256 public immutable DESTINATION_CHAIN_ID;
    address public immutable ORIGIN_ADDRESS;
    address public immutable RECEIVER_ADDRESS;
    uint64 public immutable CALLBACK_GAS_LIMIT;
    address public immutable SUBSCRIPTION_ADMIN;

    uint256 public constant PING_TOPIC = uint256(keccak256("Ping(uint256,address,uint256)"));

    bool public subscriptionConfigured;
    uint256 public observedCount;

    event SubscriptionConfigured(
        uint256 indexed destinationChainId,
        address indexed origin,
        uint256 topic0,
        uint256 topic1,
        uint256 topic2,
        uint256 topic3
    );
    event SubscriptionUnavailable();
    event PingObserved(uint256 indexed nonce, address indexed sender, uint256 originBlock);
    event PingCallbackQueued(uint256 indexed nonce, address receiver);

    modifier onlySubscriptionAdmin() {
        if (msg.sender != SUBSCRIPTION_ADMIN) revert OnlySubscriptionAdmin();
        _;
    }

    constructor(uint256 destinationChainId, address originAddress, address receiverAddress, uint64 callbackGasLimit)
        payable {
        DESTINATION_CHAIN_ID = destinationChainId;
        ORIGIN_ADDRESS = originAddress;
        RECEIVER_ADDRESS = receiverAddress;
        CALLBACK_GAS_LIMIT = callbackGasLimit;
        SUBSCRIPTION_ADMIN = msg.sender;
        _configureSubscription(false);
    }

    function configureSubscription() external onlySubscriptionAdmin {
        _configureSubscription(true);
    }

    function react(LogRecord calldata log) external vmOnly {
        uint256 nonce = log.topic_1;
        address sender = address(uint160(log.topic_2));
        observedCount++;
        emit PingObserved(nonce, sender, log.block_number);

        bytes memory payload =
            abi.encodeWithSignature("receivePing(address,uint256,uint256)", address(0), nonce, log.block_number);
        emit PingCallbackQueued(nonce, RECEIVER_ADDRESS);
        emit Callback(DESTINATION_CHAIN_ID, RECEIVER_ADDRESS, CALLBACK_GAS_LIMIT, payload);
    }

    function _configureSubscription(bool revertOnFailure) internal {
        if (vm) {
            emit SubscriptionUnavailable();
            return;
        }

        try service.subscribe(
            DESTINATION_CHAIN_ID, ORIGIN_ADDRESS, PING_TOPIC, REACTIVE_IGNORE, REACTIVE_IGNORE, REACTIVE_IGNORE
        ) {
            subscriptionConfigured = true;
            emit SubscriptionConfigured(
                DESTINATION_CHAIN_ID, ORIGIN_ADDRESS, PING_TOPIC, REACTIVE_IGNORE, REACTIVE_IGNORE, REACTIVE_IGNORE
            );
        } catch {
            if (revertOnFailure) revert SubscriptionFailed();
            emit SubscriptionUnavailable();
        }
    }
}
