use alloy_network::EthereumWallet;
use alloy_primitives::Address;
use alloy_provider::{Provider, ProviderBuilder};
use alloy_rpc_types::TransactionRequest;
use alloy_signer_local::PrivateKeySigner;
use alloy_sol_types::{sol, SolValue};
use eyre::Result;
use serde_json::Value;
use std::env;
use std::fs;
use std::str::FromStr;

sol! {
    #[sol(rpc)]
    interface IFibonacciSimple {
        struct PublicValuesStruct {
            uint32 n;
            uint32 a;
            uint32 b;
        }

        function verifyFibonacciProof(bytes calldata proofBytes, bytes calldata publicValues) 
            external view returns (uint32 n, uint32 a, uint32 b);
            
        function getProgramVKey() external view returns (bytes32);
    }
}

#[tokio::main]
async fn main() -> Result<()> {
    dotenv::dotenv().ok();
    env_logger::init();

    println!("🔍 SP1 On-Chain Proof Verification");
    println!("==================================");

    // Load contract address
    let contract_address = env::var("FIBONACCI_CONTRACT_ADDRESS")
        .unwrap_or_else(|_| "0x44a4c90114d64A027DB4630639153DC54eaA6224".to_string());
    
    println!("📝 Contract Address: {}", contract_address);
    
    // Setup provider
    let rpc_url = env::var("RPC_URL").unwrap_or_else(|_| "https://rpc.sepolia.succinct.xyz".to_string());
    let provider = ProviderBuilder::new().on_http(rpc_url.parse()?);
    
    // Parse contract address
    let contract_address = Address::from_str(&contract_address)?;
    
    println!("🔍 Reading contract call data...");
    
    // Read contract call data
    let call_data_path = "artifacts/contract_call_data_n10.json";
    if !std::path::Path::new(call_data_path).exists() {
        println!("❌ Contract call data not found at {}", call_data_path);
        println!("   Please run: cargo run --release --bin network_evm -- --system plonk");
        return Ok(());
    }
    
    let call_data_content = fs::read_to_string(call_data_path)?;
    let call_data: Value = serde_json::from_str(&call_data_content)?;
    
    // Extract proof bytes and public values
    let proof_bytes = call_data["parameters"]["proofBytes"]
        .as_str()
        .ok_or_else(|| eyre::eyre!("Missing proofBytes"))?;
    let public_values = call_data["parameters"]["publicValues"]
        .as_str()
        .ok_or_else(|| eyre::eyre!("Missing publicValues"))?;
    
    println!("🔍 Proof bytes length: {}", proof_bytes.len());
    println!("🔍 Public values: {}", public_values);
    
    // Convert hex strings to bytes
    let proof_bytes = hex::decode(proof_bytes.strip_prefix("0x").unwrap_or(proof_bytes))?;
    let public_values_bytes = hex::decode(public_values.strip_prefix("0x").unwrap_or(public_values))?;
    
    println!("📊 Proof size: {} bytes", proof_bytes.len());
    println!("📊 Public values size: {} bytes", public_values_bytes.len());
    
    // Create contract instance
    let contract = IFibonacciSimple::new(contract_address, provider);
    
    println!("🔍 Checking contract VKey...");
    let vkey = contract.getProgramVKey().call().await?;
    println!("🔑 Contract VKey: 0x{}", hex::encode(vkey._0));
    
    println!("🔍 Calling verifyFibonacciProof...");
    
    // Call verifyFibonacciProof
    let result = contract.verifyFibonacciProof(proof_bytes.into(), public_values_bytes.into()).call().await;
    
    match result {
        Ok(response) => {
            println!("✅ Proof verification successful!");
            println!("📊 Results:");
            println!("   n: {}", response.n);
            println!("   Fibonacci({}) = {}", response.n - 1, response.a);
            println!("   Fibonacci({}) = {}", response.n, response.b);
            
            // Verify the math
            if response.n == 10 && response.a == 55 && response.b == 89 {
                println!("🎉 Mathematics verified correctly!");
                println!("   Fibonacci(9) = 55 ✓");
                println!("   Fibonacci(10) = 89 ✓");
            } else {
                println!("⚠️  Unexpected values returned");
            }
        }
        Err(e) => {
            println!("❌ Proof verification failed!");
            println!("   Error: {}", e);
            
            // Try to provide more specific error information
            if e.to_string().contains("revert") {
                println!("   This might be due to:");
                println!("   - Invalid proof data");
                println!("   - Wrong program VKey");
                println!("   - Contract not properly deployed");
            }
        }
    }
    
    Ok(())
} 