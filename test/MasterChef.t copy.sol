// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {MasterChef} from "../src/MasterChef.sol";
import {SushiToken} from "../src/SushiToken.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// 一个简单的 Mock LP 代币，带有一个供测试用的 mint 函数
contract MockLP is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}

contract MasterChefTest is Test {
    MasterChef public chef;
    SushiToken public sushi;
    MockLP public lp;

    address public owner = address(1);
    address public alice = address(2);
    address public dev = address(3);

    uint256 public constant SUSHI_PER_BLOCK = 100 * 1e18;
    uint256 public constant START_BLOCK = 0;
    uint256 public constant BONUS_END_BLOCK = 1000;

    function setUp() public {
        // 1. 以 owner 身份开始部署
        vm.startPrank(owner);

        // 2. 部署 SushiToken
        sushi = new SushiToken( );

        // 3. 部署 MasterChef
        chef = new MasterChef(
            sushi,
            dev,
            SUSHI_PER_BLOCK,
            START_BLOCK,
            BONUS_END_BLOCK
        );

        // 4. *** 关键一步：将 Sushi 的所有权移交给 MasterChef ***
        // 只有这样 MasterChef 才有权限 mint 奖励
        sushi.transferOwnership(address(chef));

        // 5. 部署一个 Mock LP 代币
        lp = new MockLP("LP Token", "LP");

        // 6. 在 MasterChef 中添加矿池 (100 权重)
        chef.add(100, lp, true);

        vm.stopPrank();

        // 7. 给 Alice 准备点 LP 资产
        lp.mint(alice, 1000 * 1e18);
    }

    function test_InitialState() public {
        assertEq(address(chef.sushi()), address(sushi));
        assertEq(chef.poolLength(), 1);
        assertEq(sushi.owner(), address(chef));
    }

    function test_Deposit() public {
        uint256 depositAmount = 100 * 1e18;

        vm.startPrank(alice);
        // 授权并存入
        lp.approve(address(chef), depositAmount);
        chef.deposit(0, depositAmount);
        vm.stopPrank();

        (uint256 amount, ) = chef.userInfo(0, alice);
        assertEq(amount, depositAmount);
        assertEq(lp.balanceOf(address(chef)), depositAmount);
    }

    function test_PendingSushiAndHarvest() public {
        uint256 depositAmount = 100 * 1e18;

        // Alice 存入 LP
        vm.startPrank(alice);
        lp.approve(address(chef), depositAmount);
        chef.deposit(0, depositAmount);

        // 模拟时间推移：前进 10 个区块
        // 注意：因为在 BONUS_END_BLOCK 以内，multiplier 是 10
        vm.roll(block.number + 10);

        // 检查待领取的收益
        // 收益计算: 10 blocks * 10 multiplier * 100 sushiPerBlock = 10000 sushi
        uint256 pending = chef.pendingSushi(0, alice);
        console.log("Pending Sushi:", pending / 1e18);
        assertEq(pending, 10 * 10 * SUSHI_PER_BLOCK);

        // Alice 调用 deposit(0, 0) 来 Harvest 收益
        uint256 balBefore = sushi.balanceOf(alice);
        chef.deposit(0, 0);
        uint256 balAfter = sushi.balanceOf(alice);

        assertEq(balAfter - balBefore, pending);
        console.log("Alice Harvested Sushi:", (balAfter - balBefore) / 1e18);
        vm.stopPrank();
    }

    function test_Withdraw() public {
        uint256 depositAmount = 100 * 1e18;

        vm.startPrank(alice);
        lp.approve(address(chef), depositAmount);
        chef.deposit(0, depositAmount);

        vm.roll(block.number + 5);

        // 全部取出
        chef.withdraw(0, depositAmount);
        vm.stopPrank();

        (uint256 amount, ) = chef.userInfo(0, alice);
        assertEq(amount, 0);
        assertEq(lp.balanceOf(alice), 1000 * 1e18);
        assertTrue(sushi.balanceOf(alice) > 0);
    }

    function test_EmergencyWithdraw() public {
        uint256 depositAmount = 100 * 1e18;

        vm.startPrank(alice);
        lp.approve(address(chef), depositAmount);
        chef.deposit(0, depositAmount);
        
        // 紧急提现：只拿回本金，放弃收益
        chef.emergencyWithdraw(0);
        vm.stopPrank();

        assertEq(lp.balanceOf(alice), 1000 * 1e18);
        assertEq(sushi.balanceOf(alice), 0);
    }
}
