// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";

interface IDepositQueue {
    function sweepERC20(address token) external;
}

interface IRoleManager {
    function grantRole(bytes32 role, address account) external;
    function ERC20_REWARD_ADMIN() external view returns (bytes32);
}

contract RenzoBugTest is Test {

    address erc20RewardsAdmin;
    address attacker;

    address private constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address private constant roleManagerDefaultAdmin = 0xD1e6626310fD54Eceb5b9a51dA2eC329D6D4B68A;

    IDepositQueue private _depositQueue = IDepositQueue(0xf2F305D14DCD8aaef887E0428B3c9534795D0d60);
    IRoleManager private _roleManager = IRoleManager(0x4994EFc62101A9e3F885d872514c2dC7b3235849);

    function setUp() public {
        vm.selectFork(vm.createFork(vm.envString("ETH_RPC_URL")));

        _grantRole();
    }

    // function testBugPoc(uint256 _amount1, uint256 _amount2) public {
    //     vm.assume(_amount1 < 10 ether && _amount2 < 10 ether);

    //     deal({ token: USDT, to: address(_depositQueue), give: _amount1 * 10 ** 6 });
    //     vm.prank(erc20RewardsAdmin);
    //     _depositQueue.sweepERC20(USDT);

    //     deal({ token: USDT, to: address(_depositQueue), give: _amount2 * 10 ** 6 });
    //     vm.prank(erc20RewardsAdmin);
    //     _depositQueue.sweepERC20(USDT);
    // }
    function testBugPoc() public {
        address _weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        address _token = _weth;
        // address _token = USDT;
        deal({ token: _token, to: address(_depositQueue), give: 1 ether });
        vm.prank(erc20RewardsAdmin);
        _depositQueue.sweepERC20(_token);
    }

    function _grantRole() internal {
        _setUpAccounts();

        vm.startPrank(roleManagerDefaultAdmin);
        _roleManager.grantRole(
            _roleManager.ERC20_REWARD_ADMIN(),
            erc20RewardsAdmin
        );
        vm.stopPrank();
    }

    function _setUpAccounts() internal {
        erc20RewardsAdmin = makeAddr("erc20RewardsAdmin");

        attacker = makeAddr("attacker");
        deal({ token: USDT, to: attacker, give: 1_000_000 * 10 ** 6 });
    }
}
