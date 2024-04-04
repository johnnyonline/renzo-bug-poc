// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {DummyToken} from "./DummyToken.sol";
import {DummyStrategy} from "./DummyStrategy.sol";

import "forge-std/Test.sol";
import "forge-std/console.sol";

interface IDepositQueue {
    function sweepERC20(address token) external;
    function setFeeConfig(address _feeAddress, uint256 _feeBasisPoints) external;
}

interface IRoleManager {
    function grantRole(bytes32 role, address account) external;
    function ERC20_REWARD_ADMIN() external view returns (bytes32);
    function OPERATOR_DELEGATOR_ADMIN() external view returns (bytes32);
    function RESTAKE_MANAGER_ADMIN() external view returns (bytes32);
}

interface IOperatorDelegator {
    function setTokenStrategy(address _token, address _strategy) external;
}

interface IStrategyManager {
    function unpause(uint256 newPausedStatus) external;
    function addStrategiesToDepositWhitelist(address[] calldata strategiesToWhitelist) external;
}

contract RenzoBugTest is Test {

    address admin;

    address private constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address private constant roleManagerDefaultAdmin = 0xD1e6626310fD54Eceb5b9a51dA2eC329D6D4B68A;
    address private constant _elExecutorMsig = 0x369e6F597e22EaB55fFb173C6d9cD234BD699111; // strategyManager.pauserRegistry.unpauser()
    address private constant _elOperationsMsig = 0xBE1685C81aA44FF9FB319dD389addd9374383e90; // strategyManager.strategyWhitelister()

    IDepositQueue private _depositQueue = IDepositQueue(0xf2F305D14DCD8aaef887E0428B3c9534795D0d60);
    IRoleManager private _roleManager = IRoleManager(0x4994EFc62101A9e3F885d872514c2dC7b3235849);
    IOperatorDelegator private _operatorDelegator = IOperatorDelegator(0x125B367C16C5858f11e12948404F7a1371a0FDa3);
    IStrategyManager private _strategyManager = IStrategyManager(0x858646372CC42E1A627fcE94aa7A7033e7CF075A);

    DummyToken private _dummyToken;
    DummyStrategy private _dummyStrategy;

    function setUp() public {
        vm.selectFork(vm.createFork(vm.envString("ETH_RPC_URL")));

        // set up admin account
        admin = makeAddr("admin");

        // grant roles
        vm.startPrank(roleManagerDefaultAdmin);
        _roleManager.grantRole(_roleManager.ERC20_REWARD_ADMIN(), admin);
        _roleManager.grantRole(_roleManager.OPERATOR_DELEGATOR_ADMIN(), admin);
        _roleManager.grantRole(_roleManager.RESTAKE_MANAGER_ADMIN(), admin);
        vm.stopPrank();

        // deploy dummy token with an unexpected approve function
        _dummyToken = new DummyToken();

        // deploy dummy strategy
        _dummyStrategy = new DummyStrategy();

        // enable the a strategy for the dummy token
        vm.prank(admin);
        _operatorDelegator.setTokenStrategy(address(_dummyToken), address(_dummyStrategy));

        // unpause the strategy
        vm.prank(_elExecutorMsig);
        _strategyManager.unpause(0);

        // whitelist the strategy
        address[] memory _strategiesToWhitelist = new address[](1);
        _strategiesToWhitelist[0] = address(_dummyStrategy);
        vm.prank(_elOperationsMsig);
        _strategyManager.addStrategiesToDepositWhitelist(_strategiesToWhitelist);

    }

    // Conclusion: The bug does not exist because the contract always transfers the full allowance
    function testCantHandleZeroAllowanceBug(uint256 _amount1, uint256 _amount2, uint256 _fee) public {
        vm.assume(_amount1 < 10 ether && _amount1 > 0);
        vm.assume(_amount2 < 10 ether && _amount2 > 0);
        vm.assume(_fee < 10000);

        vm.prank(admin);
        _depositQueue.setFeeConfig(admin, _fee);

        address _token = address(_dummyToken);

        deal({ token: _token, to: address(_depositQueue), give: _amount1 });
        vm.prank(admin);
        _depositQueue.sweepERC20(_token);

        deal({ token: _token, to: address(_depositQueue), give: _amount2 });
        vm.prank(admin);
        _depositQueue.sweepERC20(_token);
    }

    // Conclusion: The bug exist, sweepERC20() fails when trying to approve a USDT spend, because it expects a return value
    //             and the approve function in the USDT contract does not return anything
    function testCantHandleNoReturnValueBug() public {
        deal({ token: USDT, to: address(_depositQueue), give: 1 ether });
        vm.startPrank(admin);
        vm.expectRevert();
        _depositQueue.sweepERC20(USDT);
        vm.stopPrank();
    }
}
