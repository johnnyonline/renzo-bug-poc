// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DummyToken is ERC20 {

    constructor() ERC20("Dummy", "DUM") {
        _mint(msg.sender, 1000000 * 10 ** 18);
    }

    function approve(address _spender, uint256 _value) public override returns (bool) {

        address _owner = _msgSender();

        // To change the approve amount you first have to reduce the addresses`
        //  allowance to zero by calling `approve(_spender, 0)` if it is not
        //  already 0 to mitigate the race condition described here:
        //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        require(!((_value != 0) && (allowance(_owner, _spender) != 0)));

        _approve(_owner, _spender, _value);

        return true;
    }
}