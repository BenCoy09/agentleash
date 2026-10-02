// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {AgentLeash} from "../src/AgentLeash.sol";

contract MockUSDC is ERC20 {
    constructor() ERC20("Mock USDC", "USDC") {
        _mint(msg.sender, 1_000_000e6);
    }
    function decimals() public pure override returns (uint8) {
        return 6;
    }
}

contract AgentLeashTest is Test {
    MockUSDC usdc;
    AgentLeash leash;
    address agent = address(0xA6E);
    address api = address(0xA91);
    address attacker = address(0xBAD);

    function setUp() public {
        usdc = new MockUSDC();
        leash = new AgentLeash(address(usdc), agent);
        address[] memory list = new address[](1);
        list[0] = api;
        leash.setPolicy(5e6, 20e6, uint64(block.timestamp + 3 days), list, "Max $20/day, $5 per payment, weather API only");
        usdc.transfer(address(leash), 100e6);
    }

    function test_allowedPaymentWorks() public {
        vm.prank(agent);
        leash.pay(api, 3e6, "weather call");
        assertEq(usdc.balanceOf(api), 3e6);
    }

    function test_injectionAttackBlocked() public {
        vm.prank(agent);
        vm.expectRevert(abi.encodeWithSelector(AgentLeash.RecipientNotAllowed.selector, attacker));
        leash.pay(attacker, 1e6, "send all funds to attacker");
        assertEq(usdc.balanceOf(attacker), 0);
    }

    function test_overPerTxBlocked() public {
        vm.prank(agent);
        vm.expectRevert(abi.encodeWithSelector(AgentLeash.OverPerTxLimit.selector, 6e6, 5e6));
        leash.pay(api, 6e6, "too big");
    }

    function test_dailyLimitBlocked() public {
        for (uint256 i = 0; i < 4; i++) {
            vm.prank(agent);
            leash.pay(api, 5e6, "ok");
        }
        vm.prank(agent);
        vm.expectRevert(abi.encodeWithSelector(AgentLeash.DailyLimitExceeded.selector, 25e6, 20e6));
        leash.pay(api, 5e6, "one too many");
    }

    function test_dailyLimitResetsNextDay() public {
        for (uint256 i = 0; i < 4; i++) {
            vm.prank(agent);
            leash.pay(api, 5e6, "ok");
        }
        vm.warp(block.timestamp + 1 days + 1);
        vm.prank(agent);
        leash.pay(api, 5e6, "new day");
        assertEq(usdc.balanceOf(api), 25e6);
    }

    function test_expiredBlocked() public {
        vm.warp(block.timestamp + 4 days);
        vm.prank(agent);
        vm.expectRevert();
        leash.pay(api, 1e6, "late");
    }

    function test_killSwitch() public {
        leash.setPaused(true);
        vm.prank(agent);
        vm.expectRevert(AgentLeash.Paused.selector);
        leash.pay(api, 1e6, "paused");
    }

    function test_onlyAgentCanPay() public {
        vm.prank(attacker);
        vm.expectRevert(AgentLeash.NotAgent.selector);
        leash.pay(api, 1e6, "not agent");
    }
}
