// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IStrategy {
    function deposit(address token, uint256 amount) external returns (uint256 newShares);
}

contract DummyStrategy is IStrategy {

    uint256 private _dummyVar;

    function deposit(address, uint256) external returns (uint256) {
        _dummyVar = 1;

        return _dummyVar;
    }
}