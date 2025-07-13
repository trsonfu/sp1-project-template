// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {FibonacciSimple} from "../src/FibonacciSimple.sol";

contract DeploySimple is Script {
    function run() external {
        // Get the program verification key from environment
        bytes32 programVKey = vm.envOr("FIBONACCI_PROGRAM_VKEY", bytes32(0));
        require(programVKey != bytes32(0), "FIBONACCI_PROGRAM_VKEY must be set in .env");
        
        console.log("==============================================");
        console.log("Deploying FibonacciSimple Contract");
        console.log("==============================================");
        console.log("Program VKey:", vm.toString(programVKey));
        console.log("SP1 Verifier Gateway: 0x3B6041173B80E77f038f3F2C0f9744f04837185e");
        
        vm.startBroadcast();
        
        // Deploy the simple contract
        FibonacciSimple fibonacci = new FibonacciSimple(programVKey);
        
        vm.stopBroadcast();
        
        console.log("==============================================");
        console.log("Deployment Successful!");
        console.log("==============================================");
        console.log("Contract Address:", address(fibonacci));
        console.log("Verifier Address:", fibonacci.getVerifier());
        console.log("Program VKey:", vm.toString(fibonacci.getProgramVKey()));
        console.log("Block Number:", block.number);
        
        console.log("\nNext steps:");
        console.log("1. Generate proof: cd ../script && cargo run --release --bin network_evm");
        console.log("2. Verify on-chain with the contract address above");
    }
} 