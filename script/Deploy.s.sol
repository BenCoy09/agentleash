// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import {Script, console} from "forge-std/Script.sol";
import {AgentLeash} from "../src/AgentLeash.sol";
import {TestUSDC} from "../src/TestUSDC.sol";

contract Deploy is Script {
    function run() external {
        uint256 pk = vm.envUint("DEPLOYER_KEY");
        address agent = vm.envAddress("AGENT_ADDRESS");
        address api = vm.envAddress("API_ADDRESS");
        vm.startBroadcast(pk);
        TestUSDC usdc = new TestUSDC();
        AgentLeash leash = new AgentLeash(address(usdc), agent);
        address[] memory list = new address[](1);
        list[0] = api;
        leash.setPolicy(5e6, 20e6, uint64(block.timestamp + 7 days), list,
            "Max $20/day, $5 per payment, only the weather API, expires in 7 days");
        usdc.transfer(address(leash), 100e6);
        vm.stopBroadcast();
        console.log("TestUSDC:", address(usdc));
        console.log("AgentLeash:", address(leash));
    }
}
