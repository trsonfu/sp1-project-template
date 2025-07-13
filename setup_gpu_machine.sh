 #!/bin/bash

# SP1 Project Template - Complete Setup Script for GPU Machine
# Usage: chmod +x setup_gpu_machine.sh && ./setup_gpu_machine.sh

set -e  # Exit on any error

echo "🚀 SP1 Project Template - GPU Machine Setup"
echo "============================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_step() {
    echo -e "${BLUE}🔧 $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    print_warning "Running as root. Some steps may need adjustment."
fi

# Step 1: System Updates and Dependencies
print_step "Step 1: Installing system dependencies..."
sudo apt update
sudo apt install -y curl git build-essential pkg-config libssl-dev python3 python3-pip

# Step 2: Install Rust
print_step "Step 2: Installing Rust..."
if ! command -v rustc &> /dev/null; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source ~/.cargo/env
    print_success "Rust installed"
else
    print_success "Rust already installed"
fi

# Step 3: Install Foundry
print_step "Step 3: Installing Foundry..."
if ! command -v forge &> /dev/null; then
    curl -L https://foundry.paradigm.xyz | bash
    source ~/.bashrc
    ~/.foundry/bin/foundryup
    export PATH="$HOME/.foundry/bin:$PATH"
    print_success "Foundry installed"
else
    print_success "Foundry already installed"
fi

# Step 4: Install SP1
print_step "Step 4: Installing SP1..."
if ! command -v sp1 &> /dev/null; then
    curl -L https://sp1.succinct.xyz | bash
    source ~/.bashrc
    sp1up
    print_success "SP1 installed"
else
    print_success "SP1 already installed"
    sp1up  # Update to latest
fi

# Step 5: CUDA Setup Check
print_step "Step 5: Checking CUDA setup..."
if command -v nvidia-smi &> /dev/null; then
    nvidia-smi
    print_success "NVIDIA drivers found"
    
    if command -v nvcc &> /dev/null; then
        nvcc --version
        print_success "CUDA toolkit found"
    else
        print_warning "CUDA toolkit not found. Installing..."
        sudo apt install -y nvidia-cuda-toolkit
    fi
else
    print_error "NVIDIA drivers not found. Please install NVIDIA drivers first!"
    exit 1
fi

# Step 6: Clone SP1 Project Template
print_step "Step 6: Setting up SP1 project template..."
if [ -d "sp1-project-template" ]; then
    print_warning "sp1-project-template directory exists. Backing up..."
    mv sp1-project-template sp1-project-template.backup.$(date +%s)
fi

git clone https://github.com/succinctlabs/sp1-project-template.git
cd sp1-project-template

# Step 7: Setup Enhanced Files
print_step "Step 7: Creating enhanced contract files..."

# Create FibonacciSimple.sol
cat > contracts/src/FibonacciSimple.sol << 'EOF'
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
EOF

# Create DeploySimple.s.sol
cat > contracts/script/DeploySimple.s.sol << 'EOF'
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
        console.log("1. Generate proof: cd ../script && cargo run --release --bin gpu_evm");
        console.log("2. Verify on-chain with the contract address above");
    }
}
EOF

# Step 8: Setup Contracts
print_step "Step 8: Setting up Foundry contracts..."
cd contracts
forge install succinctlabs/sp1-contracts --no-commit
echo "@sp1-contracts/=lib/sp1-contracts/contracts/src/" >> remappings.txt
forge build
print_success "Contracts built successfully"
cd ..

# Step 9: Create GPU optimized proving script
print_step "Step 9: Creating GPU-optimized proving script..."

cat > script/src/bin/gpu_evm.rs << 'EOF'
use clap::Parser;
use sp1_sdk::{
    include_elf, ProverClient, SP1ProofWithPublicValues, SP1Stdin, HashableKey
};

/// The ELF (executable and linkable format) file for the Succinct RISC-V zkVM.
pub const FIBONACCI_ELF: &[u8] = include_elf!("fibonacci-program");

#[derive(Parser, Debug)]
#[command(name = "gpu_evm")]
#[command(about = "Generate SP1 EVM proofs using GPU")]
struct Args {
    /// The input number for Fibonacci computation
    #[arg(long, default_value = "10")]
    n: u32,

    /// The proof system to use (groth16 or plonk)
    #[arg(long, default_value = "groth16")]
    system: String,
}

fn main() {
    let args = Args::parse();
    
    println!("🚀 SP1 GPU EVM Proof Generation");
    println!("===============================");
    println!("📊 Input: n = {}", args.n);
    println!("🔧 System: {}", args.system);
    println!("🎮 Using GPU acceleration");
    println!();

    // Setup the prover client with GPU
    let client = ProverClient::from_env();

    // Setup the inputs.
    let mut stdin = SP1Stdin::new();
    stdin.write(&args.n);

    // Setup the program for proving.
    println!("🔧 Setting up program...");
    let (pk, vk) = client.setup(FIBONACCI_ELF);
    
    // Get the verification key hash for contracts
    let vk_hash = hex::encode(vk.bytes32());
    println!("🔑 Program VKey: 0x{}", vk_hash);

    // First, test execution locally
    println!("⚡ Testing local execution...");
    let (output, report) = client.execute(FIBONACCI_ELF, &stdin).run().unwrap();
    println!("✅ Local execution successful - Cycles: {}", report.total_instruction_count());

    // Generate the EVM-compatible proof using GPU
    println!("🎮 Generating {} proof using GPU...", args.system.to_uppercase());
    println!("⏳ This should be much faster on GPU...");
    
    let proof = if args.system == "groth16" {
        client.prove(&pk, &stdin).groth16().run()
    } else {
        client.prove(&pk, &stdin).plonk().run()
    }.expect("failed to generate proof");

    println!("✅ {} proof generated successfully!", args.system.to_uppercase());

    // Verify the proof locally
    println!("🔍 Verifying proof...");
    client.verify(&proof, &vk).expect("failed to verify proof");
    println!("✅ Proof verification successful!");

    // Save artifacts
    use std::fs;
    fs::create_dir_all("artifacts").unwrap();
    
    fs::write("artifacts/proof_gpu.bin", proof.bytes()).unwrap();
    fs::write("artifacts/public_values_gpu.bin", &proof.public_values.to_vec()).unwrap();
    fs::write("artifacts/vkey_gpu.txt", format!("0x{}", vk_hash)).unwrap();
    
    println!("💾 Artifacts saved to artifacts/");
    println!("🎉 GPU proof generation completed successfully!");
    
    println!("\n🔗 Next steps:");
    println!("1. Deploy contract: cd ../contracts && forge script script/DeploySimple.s.sol --broadcast");
    println!("2. Use proof artifacts for on-chain verification");
}
EOF

# Add to Cargo.toml
cd script
if ! grep -q "gpu_evm" Cargo.toml; then
    cat >> Cargo.toml << 'EOF'

[[bin]]
name = "gpu_evm"
path = "src/bin/gpu_evm.rs"
EOF
fi
cd ..

# Step 10: Create environment template
print_step "Step 10: Creating environment template..."

cat > .env.example << 'EOF'
# SP1 Project Template Environment Configuration
# Copy this file to .env and fill in your actual values

# ====== REQUIRED CONFIGURATION ======

# SP1 Prover Configuration - USE CUDA for GPU
SP1_PROVER=cuda

# SP1 Network Configuration (for network proving)
NETWORK_PRIVATE_KEY=your_sp1_network_private_key_here

# Ethereum Configuration  
PRIVATE_KEY=your_ethereum_private_key_here
RPC_URL=https://rpc.sepolia.org

# Network Selection
NETWORK=sepolia

# ====== AUTO-GENERATED (DO NOT EDIT) ======
# These will be filled automatically after running the setup scripts
FIBONACCI_PROGRAM_VKEY=
FIBONACCI_CONTRACT_ADDRESS=

# ====== GPU CONFIGURATION ======
# Use both GPUs if available
CUDA_VISIBLE_DEVICES=0,1

# ====== OPTIONAL ======
ETHERSCAN_API_KEY=your_etherscan_key
EOF

# Step 11: Build everything
print_step "Step 11: Building project..."
cd script
cargo build --release
print_success "Rust project built successfully"
cd ..

# Step 12: Generate verification key
print_step "Step 12: Generating verification key..."
cd script
VK_OUTPUT=$(cargo run --release --bin vkey 2>/dev/null | tail -1)
if [[ $VK_OUTPUT =~ 0x[a-fA-F0-9]{64} ]]; then
    VK_VALUE=$VK_OUTPUT
    print_success "Verification key generated: $VK_VALUE"
    
    # Update .env.example with the actual VK
    cd ..
    sed -i "s/FIBONACCI_PROGRAM_VKEY=/FIBONACCI_PROGRAM_VKEY=$VK_VALUE/" .env.example
    cp .env.example .env
    print_success ".env file created with verification key"
else
    print_warning "Could not extract verification key automatically"
    cd ..
    cp .env.example .env
fi

# Step 13: Create quick start scripts
print_step "Step 13: Creating quick start scripts..."

cat > run_gpu_proving.sh << 'EOF'
#!/bin/bash
echo "🎮 Starting GPU proof generation..."
export SP1_PROVER=cuda
export CUDA_VISIBLE_DEVICES=0,1
cd script
cargo run --release --bin gpu_evm
EOF

cat > deploy_contract.sh << 'EOF'
#!/bin/bash
echo "🚀 Deploying contract..."
if [ -z "$RPC_URL" ] || [ -z "$PRIVATE_KEY" ]; then
    echo "❌ Please set RPC_URL and PRIVATE_KEY environment variables"
    echo "Example: export RPC_URL='https://rpc.sepolia.org'"
    echo "Example: export PRIVATE_KEY='0x...'"
    exit 1
fi

cd contracts
forge script script/DeploySimple.s.sol --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast
EOF

cat > test_gpu.sh << 'EOF'
#!/bin/bash
echo "🧪 Testing GPU setup..."
echo "CUDA devices:"
nvidia-smi --query-gpu=name,memory.total --format=csv
echo ""
echo "CUDA toolkit:"
nvcc --version
echo ""
echo "Environment:"
echo "SP1_PROVER=cuda"
echo "CUDA_VISIBLE_DEVICES=0,1"
EOF

chmod +x run_gpu_proving.sh deploy_contract.sh test_gpu.sh

# Final instructions
print_step "Setup completed! 🎉"
echo ""
print_success "SP1 Project Template setup completed successfully!"
echo ""
echo "📋 Next steps:"
echo "1. Edit .env file with your keys:"
echo "   - PRIVATE_KEY: Your Ethereum private key"
echo "   - NETWORK_PRIVATE_KEY: Your SP1 network private key (optional)"
echo "   - RPC_URL: Ethereum RPC endpoint"
echo ""
echo "2. Test GPU setup:"
echo "   ./test_gpu.sh"
echo ""
echo "3. Generate GPU proof:"
echo "   ./run_gpu_proving.sh"
echo ""
echo "4. Deploy contract:"
echo "   export RPC_URL='https://rpc.sepolia.org'"
echo "   export PRIVATE_KEY='0x...'"
echo "   ./deploy_contract.sh"
echo ""
echo "5. Manual commands:"
echo "   cd script && export SP1_PROVER=cuda && cargo run --release --bin gpu_evm"
echo ""
print_warning "Don't forget to edit .env file with your actual keys!"
echo ""
print_success "Happy proving! 🚀"
EOF

chmod +x setup_gpu_machine.sh