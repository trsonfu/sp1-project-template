//! Enhanced Network EVM Proof Generation Script
//! 
//! This script generates EVM-compatible proofs using the Succinct Prover Network
//! and prepares them for on-chain verification.

use alloy_sol_types::SolType;
use clap::Parser;
use fibonacci_lib::PublicValuesStruct;
use sp1_sdk::{
    include_elf, ProverClient, SP1ProofWithPublicValues, SP1Stdin, HashableKey
};



/// The ELF (executable and linkable format) file for the Succinct RISC-V zkVM.
pub const FIBONACCI_ELF: &[u8] = include_elf!("fibonacci-program");

/// The arguments for the command.
#[derive(Parser, Debug)]
#[command(author, version, about, long_about = None)]
struct Args {
    /// The input number for Fibonacci computation
    #[arg(long, default_value = "10")]
    n: u32,

    /// The proof system to use (groth16 or plonk)
    #[arg(long, default_value = "groth16")]
    system: String,

    /// Whether to save proof artifacts
    #[arg(long, default_value = "true")]
    save_artifacts: bool,

    /// Output directory for artifacts
    #[arg(long, default_value = "artifacts")]
    output_dir: String,
}

fn main() {
    // Setup the logger.
    sp1_sdk::utils::setup_logger();
    dotenv::dotenv().ok();

    // Parse the command line arguments.
    let args = Args::parse();

    let prover_mode = std::env::var("SP1_PROVER").unwrap_or_else(|_| "local".to_string());
    
    println!("🚀 SP1 Network EVM Proof Generation");
    println!("===================================");
    println!("📊 Input: n = {}", args.n);
    println!("🔧 System: {}", args.system);
    println!("🌐 Prover Mode: {}", prover_mode);
    println!();

    // Validate system argument
    if args.system != "groth16" && args.system != "plonk" {
        eprintln!("❌ Error: system must be either 'groth16' or 'plonk'");
        std::process::exit(1);
    }

    // Setup the prover client.
    let client = ProverClient::from_env();

    // Setup the inputs.
    let mut stdin = SP1Stdin::new();
    stdin.write(&args.n);

    // Setup the program for proving.
    println!("🔧 Setting up program...");
    let (pk, vk) = client.setup(FIBONACCI_ELF);
    
    // Get the verification key hash for contracts
    let vk_bytes = vk.bytes32();
    
    // vk.bytes32() actually returns a String already!
    println!("🔍 Debug vk_bytes: {:?}", vk_bytes);
    println!("🔍 vk_bytes type: String");
    
    // Since vk_bytes is already a hex string, use it directly
    let vk_hash = if vk_bytes.starts_with("0x") {
        vk_bytes[2..].to_string()  // Remove "0x" prefix if present
    } else {
        vk_bytes.clone()
    };
    
    println!("🔑 Program VKey: 0x{}", vk_hash);

    // First, test execution locally to ensure everything works
    println!("⚡ Testing local execution...");
    let (output, report) = client.execute(FIBONACCI_ELF, &stdin).run().unwrap();
    
    // Read and validate the output
    let decoded = PublicValuesStruct::abi_decode(output.as_slice(), true).unwrap();
    println!("✅ Local execution successful:");
    println!("   Input n: {}", decoded.n);
    println!("   Fibonacci({}): {}", decoded.n.saturating_sub(1), decoded.a);
    println!("   Fibonacci({}): {}", decoded.n, decoded.b);
    println!("   Cycles: {}", report.total_instruction_count());
    println!();

    // Generate the EVM-compatible proof
    match prover_mode.as_str() {
        "network" => {
            println!("🌐 Generating {} proof using Succinct Prover Network...", args.system.to_uppercase());
            println!("⏳ This may take several minutes depending on network load...");
        },
        "cpu" => {
            println!("💻 Generating {} proof using CPU...", args.system.to_uppercase());
            println!("⚠️  WARNING: CPU proving can take HOURS for Groth16! Consider using 'mock' for testing.");
        },
        "mock" => {
            println!("🎭 Generating {} mock proof...", args.system.to_uppercase());
            println!("⚡ Mock proving is fast but proofs are not secure!");
        },
        _ => {
            println!("🔧 Generating {} proof using {}...", args.system.to_uppercase(), prover_mode);
        }
    }
    
    let proof = if args.system == "groth16" {
        client.prove(&pk, &stdin).groth16().run()
    } else {
        client.prove(&pk, &stdin).plonk().run()
    }.expect("failed to generate proof");

    match prover_mode.as_str() {
        "mock" => println!("✅ {} mock proof generated successfully!", args.system.to_uppercase()),
        _ => println!("✅ {} proof generated successfully!", args.system.to_uppercase()),
    }

    // Verify the proof locally
    println!("🔍 Verifying proof...");
    client.verify(&proof, &vk).expect("failed to verify proof");
    println!("✅ Proof verification successful!");

    // Process and save artifacts if requested
    if args.save_artifacts {
        save_proof_artifacts(&proof, &args, &vk_hash).expect("failed to save artifacts");
    }

    // Display final information
    println!();
    println!("🎉 Proof generation completed successfully!");
    println!("📋 Summary:");
    println!("   Input: {}", args.n);
    println!("   System: {}", args.system);
    println!("   VKey: 0x{}", vk_hash);
    println!("   Public Values: 0x{}", hex::encode(&proof.public_values.to_vec()));
    println!("   Proof Size: {} bytes", proof.bytes().len());
    
    if args.save_artifacts {
        println!("   Artifacts saved to: {}/", args.output_dir);
    }

    println!();
    println!("🔗 Next steps for on-chain verification:");
    println!("1. Set FIBONACCI_PROGRAM_VKEY=0x{} in your .env", vk_hash);
    println!("2. Deploy contract: cd ../contracts && forge script script/Deploy.s.sol --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast");
    println!("3. Call verifyFibonacciProof with the generated proof and public values");
}

/// Save proof artifacts for on-chain verification
fn save_proof_artifacts(
    proof: &SP1ProofWithPublicValues,
    args: &Args,
    vk_hash: &str,
) -> Result<(), Box<dyn std::error::Error>> {
    use std::fs;

    // Create output directory
    fs::create_dir_all(&args.output_dir)?;

    // Save proof bytes
    let proof_path = format!("{}/proof_{}_n{}.bin", args.output_dir, args.system, args.n);
    fs::write(&proof_path, proof.bytes())?;
    println!("💾 Proof saved to: {}", proof_path);

    // Save public values
    let public_values_path = format!("{}/public_values_n{}.bin", args.output_dir, args.n);
    fs::write(&public_values_path, &proof.public_values.to_vec())?;
    println!("💾 Public values saved to: {}", public_values_path);

    // Save verification key
    let vkey_path = format!("{}/verification_key.txt", args.output_dir);
    fs::write(&vkey_path, format!("0x{}", vk_hash))?;
    println!("💾 Verification key saved to: {}", vkey_path);

    // Save contract call data
    let call_data = generate_contract_call_data(proof, args.n)?;
    let call_data_path = format!("{}/contract_call_data_n{}.json", args.output_dir, args.n);
    fs::write(&call_data_path, call_data)?;
    println!("💾 Contract call data saved to: {}", call_data_path);

    // Save human-readable summary
    let summary = format!(
        "SP1 {} Proof Summary\n\
        ===================\n\
        Input: {}\n\
        System: {}\n\
        Verification Key: 0x{}\n\
        Public Values: 0x{}\n\
        Proof: 0x{}\n\
        Proof Size: {} bytes\n\
        \n\
        To verify on-chain:\n\
        1. Deploy Fibonacci contract with VKey: 0x{}\n\
        2. Call verifyFibonacciProof(publicValues, proof)\n\
        3. Public Values: 0x{}\n\
        4. Proof: 0x{}\n",
        args.system.to_uppercase(),
        args.n,
        args.system,
        vk_hash,
        hex::encode(&proof.public_values.to_vec()),
        hex::encode(&proof.bytes()),
        proof.bytes().len(),
        vk_hash,
        hex::encode(&proof.public_values.to_vec()),
        hex::encode(&proof.bytes())
    );

    let summary_path = format!("{}/summary_n{}.txt", args.output_dir, args.n);
    fs::write(&summary_path, summary)?;
    println!("💾 Summary saved to: {}", summary_path);

    Ok(())
}

/// Generate contract call data in JSON format
fn generate_contract_call_data(
    proof: &SP1ProofWithPublicValues,
    n: u32,
) -> Result<String, Box<dyn std::error::Error>> {
    use serde_json::json;

    let call_data = json!({
        "function": "verifyFibonacciProof",
        "parameters": {
            "publicValues": format!("0x{}", hex::encode(&proof.public_values.to_vec())),
            "proofBytes": format!("0x{}", hex::encode(&proof.bytes()))
        },
        "expected_output": {
            "n": n,
            "decoded_from_public_values": "Use abi.decode(publicValues, (PublicValuesStruct))"
        },
        "contract_interface": {
            "function_signature": "verifyFibonacciProof(bytes,bytes)",
            "returns": "(uint32,uint32,uint32)"
        }
    });

    Ok(serde_json::to_string_pretty(&call_data)?)
} 