// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {MockToken} from "../src/MockToken.sol";
import {IERC1363Receiver} from "@openzeppelin/contracts/interfaces/IERC1363Receiver.sol";

// 一个简单的接收者合约，用来测试 ERC1363 的回调逻辑
contract TokenReceiver is IERC1363Receiver {
    bool public received;

    function onTransferReceived(
        address, 
        address, 
        uint256, 
        bytes calldata
    ) external override returns (bytes4) {
        received = true;
        return IERC1363Receiver.onTransferReceived.selector;
    }
}

contract MockTest is Test {
    MockToken public mockToken;
    address public owner = address(1);
    address public user = address(2);

    function setUp() public {
        // 给 owner 部署并初始铸造 100万个
        vm.prank(owner);
        mockToken = new MockToken(owner, owner);
    }

    // 1. 测试你的 freeMint 逻辑 (包含 _update 的铸造功能)
    function test_FreeMint() public {
        uint256 mintAmount = 2;
        mockToken.freeMint(user, mintAmount);
        
        uint256 expectedBalance = mintAmount * 10 ** mockToken.decimals();
        assertEq(mockToken.balanceOf(user), expectedBalance);
        console.log("User Balance after mint:", mockToken.balanceOf(user));
    }

    // 2. 测试普通的转账逻辑 (验证 _update 的转账功能)
    function test_Transfer() public {
        uint256 amount = 100 * 10**18;
        vm.prank(owner);
        mockToken.transfer(user, amount);
        
        assertEq(mockToken.balanceOf(user), amount);
        console.log("Transfer successful, _update worked.");
    }

    // 3. 测试 ERC1363 特有的功能 (验证 _update 在 ERC1363 下的特殊逻辑)
    function test_ERC1363TransferAndCall() public {
        TokenReceiver receiver = new TokenReceiver();
        uint256 amount = 50 * 10**18;

        vm.prank(owner);
        // transferAndCall 会触发 _update，并在完成后调用 receiver 的回调
        mockToken.transferAndCall(address(receiver), amount);

        assertEq(mockToken.balanceOf(address(receiver)), amount);
        assertTrue(receiver.received());
        console.log("ERC1363 callback worked!");
    }

    // 4. 修复后的 Fuzz Test
    function testFuzz_FreeMint(uint256 x) public {
        // 限制铸造量不要大到溢出 (比如限制在 100 亿个以内)
        vm.assume(x > 0 && x < 1e10); 
        
        mockToken.freeMint(user, x);
        assertEq(mockToken.balanceOf(user), x * 10 ** mockToken.decimals());
    }

    // 5. 测试 Permit (ERC20Permit 逻辑)
    function test_Permit() public {
        uint256 privateKey = 0x123;
        address alice = vm.addr(privateKey);
        
        uint256 amount = 1000 * 10**18;
        uint256 deadline = block.timestamp + 1 days;

        // 生成 Permit 签名
        (uint8 v, bytes32 r, bytes32 s) = _getPermitSignature(alice, privateKey, address(this), amount, deadline);

        mockToken.permit(alice, address(this), amount, deadline, v, r, s);
        assertEq(mockToken.allowance(alice, address(this)), amount);
        console.log("Permit worked!");
    }

    // 辅助函数：生成 ERC20Permit 签名
    function _getPermitSignature(
        address ownerAddr,
        uint256 privKey,
        address spender,
        uint256 value,
        uint256 deadline
    ) internal view returns (uint8 v, bytes32 r, bytes32 s) {
        bytes32 structHash = keccak256(
            abi.encode(
                keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"),
                ownerAddr,
                spender,
                value,
                mockToken.nonces(ownerAddr),
                deadline
            )
        );
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", mockToken.DOMAIN_SEPARATOR(), structHash));
        (v, r, s) = vm.sign(privKey, digest);
    }
}
