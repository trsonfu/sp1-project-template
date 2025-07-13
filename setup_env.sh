#!/bin/bash

# SP1 Project Template Setup Script
echo "🚀 Setting up SP1 Project Template for On-Chain Verification"
echo "============================================================"

# Copy .env.example to .env
cp .env.example .env

echo "📝 Created .env file. Please edit with your keys:"
echo ""
echo "Required environment variables:"
echo "1. NETWORK_PRIVATE_KEY - Your SP1 network private key"
echo "2. PRIVATE_KEY - Your Ethereum private key for contract deployment"
echo "3. RPC_URL - Ethereum RPC URL (use Succinct's RPC: https://rpc.sepolia.succinct.xyz)"
echo "4. ETHERSCAN_API_KEY - For contract verification on Etherscan (optional)"
echo ""
echo "Example .env configuration:"
echo "SP1_PROVER=network"
echo "NETWORK_PRIVATE_KEY=0x1234567890abcdef..."
echo "PRIVATE_KEY=0xabcdef1234567890..."
echo "RPC_URL=https://rpc.sepolia.succinct.xyz"
echo "ETHERSCAN_API_KEY=your_etherscan_key  # Optional - for contract verification"
echo ""
echo "Next steps:"
echo "1. Edit .env file with your actual keys"
echo "2. Run: cd script && cargo run --release --bin vkey"
echo "3. Update contracts with verification key"
echo "4. Deploy contracts: cd contracts && forge deploy"
echo "5. Generate EVM proofs: cd script && cargo run --release --bin evm -- --system groth16"
echo ""
echo "✅ Setup script completed!" 