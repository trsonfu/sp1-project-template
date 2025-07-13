// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {Fibonacci} from "../src/Fibonacci.sol";

/// @title Deployment Script for Enhanced Fibonacci Contract
/// @notice This script deploys the Fibonacci contract with proper configuration
/// @dev Etherscan verification is optional - contracts work without it
contract Deploy is Script {
    
    /// @notice SP1 Verifier Gateway addresses for different networks
    /// @dev Gateway can verify proofs from any SP1 version
    mapping(string => address) public verifierAddresses;
    
    function setUp() public {
        // SP1 Verifier Gateway addresses
        // Source: https://github.com/succinctlabs/sp1-contracts/tree/main/contracts/deployments
        
        // Ethereum Mainnet
        verifierAddresses["mainnet"] = 0x3B6041173B80E77f038f3F2C0f9744f04837185e;
        
        // Sepolia Testnet
        verifierAddresses["sepolia"] = 0x3B6041173B80E77f038f3F2C0f9744f04837185e;
        
        // Base Mainnet
        verifierAddresses["base"] = 0x3B6041173B80E77f038f3F2C0f9744f04837185e;
        
        // Base Sepolia
        verifierAddresses["base-sepolia"] = 0x3B6041173B80E77f038f3F2C0f9744f04837185e;
        
        // Arbitrum One
        verifierAddresses["arbitrum"] = 0x3B6041173B80E77f038f3F2C0f9744f04837185e;
        
        // Arbitrum Sepolia
        verifierAddresses["arbitrum-sepolia"] = 0x3B6041173B80E77f038f3F2C0f9744f04837185e;
    }
    
    function run() external {
        // Get network name from environment or default to sepolia
        string memory network = vm.envOr("NETWORK", string("sepolia"));
        
        // Get the verifier address for the current network
        address verifierAddress = verifierAddresses[network];
        require(verifierAddress != address(0), "Unsupported network");
        
        console.log("Deploying to network:", network);
        console.log("Using SP1 Verifier at:", verifierAddress);
        
        // Get the program verification key from environment
        bytes32 programVKey = vm.envOr("FIBONACCI_PROGRAM_VKEY", bytes32(0));
        
        if (programVKey == bytes32(0)) {
            console.log("WARNING: FIBONACCI_PROGRAM_VKEY not set!");
            console.log("Run this command first:");
            console.log("cd script && cargo run --release --bin vkey");
            console.log("Then set FIBONACCI_PROGRAM_VKEY in your .env file");
            revert("Program verification key not provided");
        }
        
        console.log("Program VKey:", vm.toString(programVKey));
        
        // Start broadcasting transactions
        vm.startBroadcast();
        
        // Deploy the Fibonacci contract
        Fibonacci fibonacci = new Fibonacci(verifierAddress, programVKey);
        
        console.log("SUCCESS: Fibonacci contract deployed at:", address(fibonacci));
        console.log("Contract owner:", fibonacci.owner());
        console.log("Verifier address:", fibonacci.verifier());
        console.log("Program VKey:", vm.toString(fibonacci.fibonacciProgramVKey()));
        
        vm.stopBroadcast();
        
        // Log deployment information
        console.log("\nDeployment completed successfully!");
        console.log("Network:", network);
        console.log("Contract:", address(fibonacci));
        console.log("Block:", block.number);
        
        // Save deployment info to file
        string memory deploymentInfo = string.concat(
            "FIBONACCI_CONTRACT_ADDRESS=", vm.toString(address(fibonacci)), "\n",
            "NETWORK=", network, "\n",
            "VERIFIER_ADDRESS=", vm.toString(verifierAddress), "\n",
            "PROGRAM_VKEY=", vm.toString(programVKey), "\n",
            "DEPLOYMENT_BLOCK=", vm.toString(block.number), "\n"
        );
        
        vm.writeFile("deployment.env", deploymentInfo);
        console.log("INFO: Deployment info saved to deployment.env");
        
        console.log("\nNext steps:");
        console.log("1. Verify contract on Etherscan:");
        console.log("   forge verify-contract", vm.toString(address(fibonacci)), "src/Fibonacci.sol:Fibonacci --watch");
        console.log("2. Generate EVM proofs:");
        console.log("   cd ../script && cargo run --release --bin evm -- --system groth16");
        console.log("3. Test verification:");
        console.log("   Cast call to verifyFibonacciProof function");
    }
    
    /// @notice Helper function to deploy to a specific network
    /// @param network The network name
    /// @param vkey The program verification key
    function deployToNetwork(string memory network, bytes32 vkey) external {
        address verifierAddress = verifierAddresses[network];
        require(verifierAddress != address(0), "Unsupported network");
        
        vm.startBroadcast();
        Fibonacci fibonacci = new Fibonacci(verifierAddress, vkey);
        vm.stopBroadcast();
        
        console.log("Deployed Fibonacci to", network, "at:", address(fibonacci));
    }
} 