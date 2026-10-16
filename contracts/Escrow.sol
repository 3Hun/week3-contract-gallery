// SPDX-License-Identifier: MIT
pragma solidity 0.8.37;

contract Escrow {
    enum State {
        AwaitingDeposit,
        Funded,
        Shipped,
        Disputed,
        Complete,
        Refunded
    }

    address payable public immutable buyer;
    address payable public immutable seller;
    address payable public immutable arbiter;
    uint256 public immutable shippingWindow;

    uint256 public deadline;
    uint256 public amount;
    State public state;

    event Deposited(uint256 amount, uint256 shippingDeadline);
    event MarkedShipped();
    event Released(uint256 amount);
    event Refunded(uint256 amount);
    event DisputeOpened(address indexed openedBy);
    event DisputeResolved(address indexed recipient, uint256 amount);

    error InvalidParty();
    error InvalidWindow();
    error NotBuyer();
    error NotSeller();
    error NotArbiter();
    error NotParticipant();
    error InvalidState();
    error ZeroDeposit();
    error ShippingDeadlinePassed();
    error RefundNotAvailable();
    error TransferFailed();

    constructor(address payable seller_, address payable arbiter_, uint256 shippingWindowSeconds) {
        address payable buyer_ = payable(msg.sender);
        if (
            seller_ == address(0) ||
            arbiter_ == address(0) ||
            seller_ == buyer_ ||
            arbiter_ == buyer_ ||
            seller_ == arbiter_
        ) revert InvalidParty();
        if (shippingWindowSeconds == 0) revert InvalidWindow();

        buyer = buyer_;
        seller = seller_;
        arbiter = arbiter_;
        shippingWindow = shippingWindowSeconds;
    }

    function deposit() external payable {
        if (msg.sender != buyer) revert NotBuyer();
        if (state != State.AwaitingDeposit) revert InvalidState();
        if (msg.value == 0) revert ZeroDeposit();

        amount = msg.value;
        deadline = block.timestamp + shippingWindow;
        state = State.Funded;
        emit Deposited(msg.value, deadline);
    }

    function markShipped() external {
        if (msg.sender != seller) revert NotSeller();
        if (state != State.Funded) revert InvalidState();
        if (block.timestamp >= deadline) revert ShippingDeadlinePassed();

        state = State.Shipped;
        emit MarkedShipped();
    }

    function release() external {
        if (msg.sender != buyer) revert NotBuyer();
        if (state != State.Shipped) revert InvalidState();

        uint256 payment = amount;
        amount = 0;
        state = State.Complete;

        (bool sent, ) = seller.call{value: payment}("");
        if (!sent) revert TransferFailed();

        emit Released(payment);
    }

    function claimRefund() external {
        if (msg.sender != buyer) revert NotBuyer();
        if (state != State.Funded || block.timestamp < deadline) {
            revert RefundNotAvailable();
        }

        uint256 refund = amount;
        amount = 0;
        state = State.Refunded;

        (bool sent, ) = buyer.call{value: refund}("");
        if (!sent) revert TransferFailed();

        emit Refunded(refund);
    }

    function openDispute() external {
        if (msg.sender != buyer && msg.sender != seller) revert NotParticipant();
        if (state != State.Funded && state != State.Shipped) revert InvalidState();
        if (state == State.Funded && block.timestamp >= deadline) {
            revert ShippingDeadlinePassed();
        }

        state = State.Disputed;
        emit DisputeOpened(msg.sender);
    }

    function resolveDispute(bool paySeller) external {
        if (msg.sender != arbiter) revert NotArbiter();
        if (state != State.Disputed) revert InvalidState();

        uint256 payment = amount;
        address payable recipient = paySeller ? seller : buyer;
        amount = 0;
        state = paySeller ? State.Complete : State.Refunded;

        (bool sent, ) = recipient.call{value: payment}("");
        if (!sent) revert TransferFailed();

        emit DisputeResolved(recipient, payment);
    }
}
