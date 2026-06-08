// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import {AbstractReactive} from "reactive-lib/abstract-base/AbstractReactive.sol";
import {IReactive} from "reactive-lib/interfaces/IReactive.sol";

contract YieldStreamRSC is IReactive, AbstractReactive {
    error SubscriptionFailed();
    error OnlySubscriptionAdmin();

    uint256 public immutable DESTINATION_CHAIN_ID;
    address public immutable HOOK_ADDRESS;
    uint64 public immutable CALLBACK_GAS_LIMIT;
    address public immutable SUBSCRIPTION_ADMIN;
    address public immutable CALLBACK_SENDER;

    uint256 public constant DEFAULT_EPOCH_LENGTH = 50_400;
    uint256 public constant FEES_ACCRUED_TOPIC = uint256(keccak256("FeesAccrued(uint256,uint256,uint256)"));

    uint256 public immutable EPOCH_LENGTH;
    uint256 public lastObservedEpoch;
    bool public initialized;
    bool public subscriptionConfigured;
    mapping(uint256 => bool) public settlementQueued;
    mapping(uint256 => uint256) public epochFeeAccumulator0;

    event SubscriptionConfigured(
        uint256 indexed destinationChainId,
        address indexed hook,
        uint256 topic0,
        uint256 topic1,
        uint256 topic2,
        uint256 topic3
    );
    event ReactiveEpochObserved(uint256 indexed epochId, uint256 blockNumber);
    event SettlementCallbackQueued(uint256 indexed epochId, address hook);
    event SubscriptionUnavailable();

    modifier onlySubscriptionAdmin() {
        if (msg.sender != SUBSCRIPTION_ADMIN) revert OnlySubscriptionAdmin();
        _;
    }

    constructor(uint256 destinationChainId, address hookAddress, uint64 callbackGasLimit, uint256 epochLength) payable {
        DESTINATION_CHAIN_ID = destinationChainId;
        HOOK_ADDRESS = hookAddress;
        CALLBACK_GAS_LIMIT = callbackGasLimit;
        EPOCH_LENGTH = epochLength == 0 ? DEFAULT_EPOCH_LENGTH : epochLength;
        SUBSCRIPTION_ADMIN = msg.sender;
        CALLBACK_SENDER = msg.sender;
        _configureSubscription(false);
    }

    function configureSubscription() external onlySubscriptionAdmin {
        _configureSubscription(true);
    }

    function _configureSubscription(bool revertOnFailure) internal {
        if (vm) {
            emit SubscriptionUnavailable();
            return;
        }

        try service.subscribe(
            DESTINATION_CHAIN_ID, HOOK_ADDRESS, FEES_ACCRUED_TOPIC, REACTIVE_IGNORE, REACTIVE_IGNORE, REACTIVE_IGNORE
        ) {
            subscriptionConfigured = true;
            emit SubscriptionConfigured(
                DESTINATION_CHAIN_ID,
                HOOK_ADDRESS,
                FEES_ACCRUED_TOPIC,
                REACTIVE_IGNORE,
                REACTIVE_IGNORE,
                REACTIVE_IGNORE
            );
        } catch {
            if (revertOnFailure) revert SubscriptionFailed();
            emit SubscriptionUnavailable();
        }
    }

    function react(LogRecord calldata log) external vmOnly {
        uint256 eventEpoch = log.topic_1;
        uint256 fee0 = log.topic_2;
        uint256 current = log.block_number / EPOCH_LENGTH;

        epochFeeAccumulator0[eventEpoch] += fee0;
        emit ReactiveEpochObserved(eventEpoch, log.block_number);

        initialized = true;
        lastObservedEpoch = eventEpoch;

        if (current > eventEpoch && !settlementQueued[eventEpoch]) {
            settlementQueued[eventEpoch] = true;
            bytes memory payload =
                abi.encodeWithSignature("settleEpochFromReactive(address,uint256)", CALLBACK_SENDER, eventEpoch);
            emit SettlementCallbackQueued(eventEpoch, HOOK_ADDRESS);
            emit Callback(DESTINATION_CHAIN_ID, HOOK_ADDRESS, CALLBACK_GAS_LIMIT, payload);
        }
    }
}
