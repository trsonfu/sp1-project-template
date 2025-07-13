//! Enhanced SP1 Program for On-Chain Verification
//! 
//! This program computes Fibonacci numbers and demonstrates:
//! - Input validation
//! - Efficient computation
//! - Structured output for on-chain verification
//! 
//! You can customize this logic for your specific use case.

// These two lines are necessary for the program to properly compile.
//
// Under the hood, we wrap your main function with some extra code so that it behaves properly
// inside the zkVM.
#![no_main]
sp1_zkvm::entrypoint!(main);

use alloy_sol_types::SolType;
use fibonacci_lib::{fibonacci, PublicValuesStruct};

pub fn main() {
    // Read input from the prover
    let n = sp1_zkvm::io::read::<u32>();

    // Input validation - prevent excessive computation
    if n > 10000 {
        panic!("Input too large: maximum allowed is 10000");
    }

    // Log the input for debugging (will appear in proof generation logs)
    println!("Computing Fibonacci for n = {}", n);

    // Compute the n'th fibonacci number using the optimized function
    let (a, b) = fibonacci(n);

    // Additional verification - ensure computation is correct
    if n == 0 {
        assert_eq!(a, 0);
        assert_eq!(b, 1);
    } else if n == 1 {
        assert_eq!(a, 1);
        assert_eq!(b, 1);
    }

    println!("Fibonacci({}) = {}, Fibonacci({}) = {}", n.saturating_sub(1), a, n, b);

    // Encode the public values using Solidity-compatible ABI encoding
    let public_values = PublicValuesStruct { n, a, b };
    let bytes = PublicValuesStruct::abi_encode(&public_values);

    // Commit to the public values - this will be verified on-chain
    sp1_zkvm::io::commit_slice(&bytes);

    println!("✅ Proof generation completed successfully!");
}

// You can add custom functions here for your specific use case
// Example:
/*
fn custom_computation(input: u32) -> u32 {
    // Your custom business logic here
    input * 2 + 1
}

fn validate_input(input: u32) -> bool {
    // Your input validation logic
    input > 0 && input < 1000000
}
*/
