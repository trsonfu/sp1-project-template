// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ISP1Verifier} from "@sp1-contracts/ISP1Verifier.sol";

/// @notice Struct representing the public values from the SP1 program
struct PublicValuesStruct {
    uint32 n;
    uint32 a;
    uint32 b;
}

/// @title Enhanced Fibonacci Verifier
/// @author Succinct Labs (Enhanced)
/// @notice This contract verifies SP1 proofs for Fibonacci computations and demonstrates
///         production-ready on-chain verification with additional features.
contract Fibonacci {
    /// @notice The address of the SP1 verifier contract.
    /// @dev This can either be a specific SP1Verifier for a specific version, or the
    ///      SP1VerifierGateway which can be used to verify proofs for any version of SP1.
    ///      For the list of supported verifiers on each chain, see:
    ///      https://github.com/succinctlabs/sp1-contracts/tree/main/contracts/deployments
    address public immutable verifier;

    /// @notice The verification key for the fibonacci program.
    bytes32 public immutable fibonacciProgramVKey;

    /// @notice The owner of the contract (can update certain settings)
    address public owner;

    /// @notice Mapping to store verified Fibonacci results
    mapping(uint32 => bool) public verifiedNumbers;

    /// @notice Mapping to store the latest Fibonacci values for each n
    mapping(uint32 => PublicValuesStruct) public fibonacciResults;

    /// @notice Total number of proofs verified
    uint256 public totalProofsVerified;

    /// @notice Events
    event FibonacciVerified(
        address indexed verifier,
        uint32 indexed n,
        uint32 fibN1,
        uint32 fibN,
        bytes32 proofHash
    );

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice Custom errors
    error InvalidProof();
    error AlreadyVerified(uint32 n);
    error InvalidInput(uint32 n);
    error OnlyOwner();

    /// @notice Modifier to restrict access to owner only
    modifier onlyOwner() {
        if (msg.sender != owner) revert OnlyOwner();
        _;
    }

    /// @notice Constructor
    /// @param _verifier The address of the SP1 verifier contract
    /// @param _fibonacciProgramVKey The verification key for the fibonacci program
    constructor(address _verifier, bytes32 _fibonacciProgramVKey) {
        verifier = _verifier;
        fibonacciProgramVKey = _fibonacciProgramVKey;
        owner = msg.sender;
    }

    /// @notice The main entrypoint for verifying Fibonacci proofs
    /// @param _publicValues The encoded public values from the SP1 program
    /// @param _proofBytes The encoded SP1 proof
    /// @return n The input number
    /// @return fibN1 The (n-1)th Fibonacci number
    /// @return fibN The nth Fibonacci number
    function verifyFibonacciProof(
        bytes calldata _publicValues,
        bytes calldata _proofBytes
    ) public returns (uint32 n, uint32 fibN1, uint32 fibN) {
        // Verify the SP1 proof
        try ISP1Verifier(verifier).verifyProof(fibonacciProgramVKey, _publicValues, _proofBytes) {
            // Proof is valid, continue
        } catch {
            revert InvalidProof();
        }

        // Decode the public values
        PublicValuesStruct memory publicValues = abi.decode(_publicValues, (PublicValuesStruct));
        
        // Basic input validation
        if (publicValues.n > 10000) {
            revert InvalidInput(publicValues.n);
        }

        // Optional: Prevent duplicate verifications
        // if (verifiedNumbers[publicValues.n]) {
        //     revert AlreadyVerified(publicValues.n);
        // }

        // Store the verified result
        verifiedNumbers[publicValues.n] = true;
        fibonacciResults[publicValues.n] = publicValues;
        totalProofsVerified++;

        // Emit event for indexing
        bytes32 proofHash = keccak256(_proofBytes);
        emit FibonacciVerified(
            msg.sender,
            publicValues.n,
            publicValues.a,
            publicValues.b,
            proofHash
        );

        return (publicValues.n, publicValues.a, publicValues.b);
    }

    /// @notice View function to check if a Fibonacci number has been verified
    /// @param n The input number to check
    /// @return verified Whether the number has been verified
    /// @return result The Fibonacci result if verified
    function getFibonacciResult(uint32 n) 
        external 
        view 
        returns (bool verified, PublicValuesStruct memory result) 
    {
        verified = verifiedNumbers[n];
        if (verified) {
            result = fibonacciResults[n];
        }
    }

    /// @notice Batch verify multiple Fibonacci proofs
    /// @param publicValuesArray Array of encoded public values
    /// @param proofBytesArray Array of encoded proofs
    function batchVerifyFibonacci(
        bytes[] calldata publicValuesArray,
        bytes[] calldata proofBytesArray
    ) external {
        require(
            publicValuesArray.length == proofBytesArray.length,
            "Arrays length mismatch"
        );

        for (uint i = 0; i < publicValuesArray.length; i++) {
            verifyFibonacciProof(publicValuesArray[i], proofBytesArray[i]);
        }
    }

    /// @notice Transfer ownership of the contract
    /// @param newOwner The new owner address
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "New owner cannot be zero address");
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /// @notice Get contract statistics
    /// @return _totalProofsVerified Total number of proofs verified
    /// @return _verifier The verifier contract address
    /// @return _programVKey The program verification key
    function getStats() 
        external 
        view 
        returns (
            uint256 _totalProofsVerified,
            address _verifier,
            bytes32 _programVKey
        ) 
    {
        return (totalProofsVerified, verifier, fibonacciProgramVKey);
    }
}
