// SPDX-License-Identifier: MIT
pragma solidity 0.8.37;

contract Faucet {
    address payable public immutable owner;
    uint256 public immutable dripAmount;
    uint256 public constant COOLDOWN = 1 days;

    mapping(address => uint256) public nextClaimAt;

    event Funded(address indexed funder, uint256 amount);
    event Claimed(address indexed claimant, uint256 amount, uint256 nextClaimAt);
    event OwnerWithdrawal(uint256 amount);

    error NotOwner();
    error InvalidDripAmount();
    error ClaimTooSoon(uint256 nextEligibleTime);
    error InsufficientBalance();
    error TransferFailed();

    constructor(uint256 dripAmountWei) {
        if (dripAmountWei == 0) revert InvalidDripAmount();
        owner = payable(msg.sender);
        dripAmount = dripAmountWei;
    }

    receive() external payable {
        emit Funded(msg.sender, msg.value);
    }

    function claim() external {
        if (block.timestamp < nextClaimAt[msg.sender]) {
            revert ClaimTooSoon(nextClaimAt[msg.sender]);
        }
        if (address(this).balance < dripAmount) revert InsufficientBalance();

        uint256 eligibleAgainAt = block.timestamp + COOLDOWN;
        nextClaimAt[msg.sender] = eligibleAgainAt;

        (bool sent, ) = payable(msg.sender).call{value: dripAmount}("");
        if (!sent) revert TransferFailed();

        emit Claimed(msg.sender, dripAmount, eligibleAgainAt);
    }

    function withdrawRemainder() external {
        if (msg.sender != owner) revert NotOwner();

        uint256 balance = address(this).balance;
        if (balance == 0) revert InsufficientBalance();

        (bool sent, ) = owner.call{value: balance}("");
        if (!sent) revert TransferFailed();

        emit OwnerWithdrawal(balance);
    }
}
