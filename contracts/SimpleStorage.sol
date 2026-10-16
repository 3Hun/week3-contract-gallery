// SPDX-License-Identifier: MIT
pragma solidity 0.8.37;

contract SimpleStorage {
    address public immutable owner;
    uint256 private storedValue;

    event ValueChanged(uint256 oldValue, uint256 newValue, address indexed changedBy);

    error NotOwner();
    error ValueUnchanged();

    constructor() {
        owner = msg.sender;
    }

    function setValue(uint256 newValue) external {
        if (msg.sender != owner) revert NotOwner();
        if (newValue == storedValue) revert ValueUnchanged();

        uint256 oldValue = storedValue;
        storedValue = newValue;
        emit ValueChanged(oldValue, newValue, msg.sender);
    }

    function getValue() external view returns (uint256) {
        return storedValue;
    }
}
