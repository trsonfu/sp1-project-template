// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ISP1Verifier} from "@sp1-contracts/ISP1Verifier.sol";

/// @notice Struct representing the public values from the SP1 program
struct PublicValuesStruct {
    uint32 n;
    uint32 a;
    uint32 b;
}

/// @title Simple Fibonacci Verifier using SP1VerifierGateway
contract FibonacciSimple {
    /// @notice The address of the SP1 Verifier Gateway (official)
    address public constant SP1_VERIFIER = 0x3B6041173B80E77f038f3F2C0f9744f04837185e;
    
    /// @notice The verification key for the fibonacci program
    bytes32 public immutable fibonacciProgramVKey;
    
    /// @notice Event emitted when a proof is verified
    event ProofVerified(uint32 indexed n, uint32 fibN);
    
    /// @notice Constructor
    constructor(bytes32 _programVKey) {
        fibonacciProgramVKey = _programVKey;
    }
    
    /// @notice Verify a fibonacci proof
    function verifyFibonacciProof(
        bytes calldata publicValues,
        bytes calldata proofBytes
    ) external {
        // Verify the SP1 proof using the official gateway
        ISP1Verifier(SP1_VERIFIER).verifyProof(fibonacciProgramVKey, publicValues, proofBytes);
        
        // Decode the public values
        PublicValuesStruct memory values = abi.decode(publicValues, (PublicValuesStruct));
        
        // Emit event
        emit ProofVerified(values.n, values.b);
    }
    
    /// @notice Get the program verification key
    function getProgramVKey() external view returns (bytes32) {
        return fibonacciProgramVKey;
    }
    
    /// @notice Get the SP1 verifier address
    function getVerifier() external pure returns (address) {
        return SP1_VERIFIER;
    }
    
    /// @notice Test function to decode public values without verification
    function testDecodePublicValues(bytes calldata publicValues) external pure returns (uint32 n, uint32 a, uint32 b) {
        PublicValuesStruct memory values = abi.decode(publicValues, (PublicValuesStruct));
        return (values.n, values.a, values.b);
    }
} 