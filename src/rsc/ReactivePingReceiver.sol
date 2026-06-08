// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface IReactiveCallbackDebt {
    function debt(address contract_) external view returns (uint256 debt_);
}

contract ReactivePingReceiver {
    error InvalidAddress();
    error OnlyOwner();
    error OnlyCallbackProxy();
    error UnexpectedReactiveSender(address actual, address expected);
    error TransferFailed();

    address public owner;
    address public callbackProxy;
    address public expectedReactiveSender;

    event CallbackProxyUpdated(address indexed callbackProxy);
    event ExpectedReactiveSenderUpdated(address indexed expectedReactiveSender);
    event PingCallbackReceived(
        address indexed injectedReactiveSender, address indexed callbackCaller, uint256 nonce, uint256 originBlock
    );

    modifier onlyOwner() {
        if (msg.sender != owner) revert OnlyOwner();
        _;
    }

    constructor(address _callbackProxy, address _expectedReactiveSender, address _owner) payable {
        if (_owner == address(0)) revert InvalidAddress();
        owner = _owner;
        callbackProxy = _callbackProxy;
        expectedReactiveSender = _expectedReactiveSender;
        emit CallbackProxyUpdated(_callbackProxy);
        emit ExpectedReactiveSenderUpdated(_expectedReactiveSender);
    }

    receive() external payable {}

    function setCallbackProxy(address _callbackProxy) external onlyOwner {
        if (_callbackProxy == address(0)) revert InvalidAddress();
        callbackProxy = _callbackProxy;
        emit CallbackProxyUpdated(_callbackProxy);
    }

    function setExpectedReactiveSender(address _expectedReactiveSender) external onlyOwner {
        expectedReactiveSender = _expectedReactiveSender;
        emit ExpectedReactiveSenderUpdated(_expectedReactiveSender);
    }

    function receivePing(address injectedReactiveSender, uint256 nonce, uint256 originBlock) external {
        if (msg.sender != callbackProxy) revert OnlyCallbackProxy();
        if (expectedReactiveSender != address(0) && injectedReactiveSender != expectedReactiveSender) {
            revert UnexpectedReactiveSender(injectedReactiveSender, expectedReactiveSender);
        }
        emit PingCallbackReceived(injectedReactiveSender, msg.sender, nonce, originBlock);
    }

    function pay(uint256 amount) external {
        if (msg.sender != callbackProxy) revert OnlyCallbackProxy();
        _pay(payable(msg.sender), amount);
    }

    function coverCallbackDebt() external {
        _pay(payable(callbackProxy), IReactiveCallbackDebt(callbackProxy).debt(address(this)));
    }

    function _pay(address payable recipient, uint256 amount) internal {
        if (amount == 0) return;
        if (address(this).balance < amount) revert TransferFailed();
        (bool success,) = recipient.call{value: amount}("");
        if (!success) revert TransferFailed();
    }
}
