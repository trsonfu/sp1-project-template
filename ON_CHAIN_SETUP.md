# 🚀 SP1 On-Chain Verification Setup Guide

This guide walks you through setting up SP1 for complete on-chain proof verification, from proof generation to smart contract deployment.

## 📋 Prerequisites

- ✅ Rust installed
- ✅ SP1 installed (`curl -L https://sp1.succinct.xyz | bash`)
- ✅ Foundry installed (`curl -L https://foundry.paradigm.xyz | bash`)
- ✅ Node.js (for Infura/Alchemy)

## 🔧 Step 1: Environment Setup

### 1.1 Run Setup Script
```bash
chmod +x setup_env.sh
./setup_env.sh
```

### 1.2 Configure .env File
Edit the generated `.env` file with your keys:

```bash
# SP1 Network Configuration
SP1_PROVER=network
NETWORK_PRIVATE_KEY=0x1234567890abcdef...  # Your SP1 network private key

# Ethereum Network Configuration
PRIVATE_KEY=0xabcdef1234567890...  # Your Ethereum private key
RPC_URL=https://rpc.sepolia.succinct.xyz  # Succinct's RPC (recommended)
ETHERSCAN_API_KEY=your_etherscan_api_key  # Optional - for contract verification

# Network Selection (sepolia, mainnet, base, arbitrum, etc.)
NETWORK=sepolia

# Contract addresses (will be filled after deployment)
FIBONACCI_PROGRAM_VKEY=
FIBONACCI_CONTRACT_ADDRESS=
```

### 1.3 Get Required Keys

**SP1 Network Private Key:**
- **Purpose**: Authenticate with SP1 Prover Network (NOT Ethereum!)
- **Visit**: https://docs.succinct.xyz/docs/network/developers/key-setup
- **Generate a new account** and get it whitelisted
- **Fund with**: SP1 network credits (not ETH)
- **Important**: This is for Succinct's internal network

**Ethereum Private Key:**
- **Purpose**: Deploy contracts to Ethereum blockchain
- **Use MetaMask** or generate with: `cast wallet new`
- **Fund with**: Sepolia ETH for gas fees
- **This is**: The private key you already have!

**RPC URL:**
- **Recommended**: Succinct's RPC: `https://rpc.sepolia.succinct.xyz`
- Alternative: Infura: https://infura.io
- Alternative: Alchemy: https://alchemy.com
- Or use public RPC (slower)

**Etherscan API Key (Optional):**
- **Purpose**: Verify contract source code on Etherscan
- **Required**: No - contracts work without verification
- **Benefits**: Makes contracts readable/auditable on Etherscan
- **Get key**: https://etherscan.io/apis

## ⚡ Step 2: Generate Verification Key

```bash
cd script
cargo run --release --bin vkey
```

This outputs your program verification key. Copy it to your .env:
```bash
FIBONACCI_PROGRAM_VKEY=0x1234567890abcdef...
```

## 🧪 Step 3: Test Local Execution

```bash
# Test the program locally
cargo run --release -- --execute --n 10

# Generate a local proof (for testing)
cargo run --release -- --prove --n 10
```

## 🌐 Step 4: Generate Network EVM Proof

### 4.1 Generate Groth16 Proof (Recommended)
```bash
cargo run --release --bin network_evm -- --n 10 --system groth16
```

### 4.2 Or Generate PLONK Proof
```bash
cargo run --release --bin network_evm -- --n 10 --system plonk
```

**Expected Output:**
```
🚀 SP1 Network EVM Proof Generation
===================================
📊 Input: n = 10
🔧 System: groth16
🌐 Using Succinct Prover Network

🔑 Program VKey: 0x1234567890abcdef...
⚡ Testing local execution...
✅ Local execution successful:
   Input n: 10
   Fibonacci(9): 34
   Fibonacci(10): 55
   Cycles: 1234

🌐 Generating GROTH16 proof using Succinct Prover Network...
⏳ This may take several minutes depending on network load...
✅ GROTH16 proof generated successfully!
🔍 Verifying proof...
✅ Proof verification successful!

💾 Proof saved to: artifacts/proof_groth16_n10.bin
💾 Public values saved to: artifacts/public_values_n10.bin
💾 Verification key saved to: artifacts/verification_key.txt
💾 Contract call data saved to: artifacts/contract_call_data_n10.json
💾 Summary saved to: artifacts/summary_n10.txt

🎉 Proof generation completed successfully!
📋 Summary:
   Input: 10
   System: groth16
   VKey: 0x1234567890abcdef...
   Public Values: 0xabcdef...
   Proof Size: 256 bytes
   Artifacts saved to: artifacts/

🔗 Next steps for on-chain verification:
1. Set FIBONACCI_PROGRAM_VKEY=0x1234567890abcdef... in your .env
2. Deploy contract: cd ../contracts && forge script script/Deploy.s.sol --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast
3. Call verifyFibonacciProof with the generated proof and public values
```

## 🏗️ Step 5: Deploy Smart Contract

### 5.1 Setup Foundry Dependencies
```bash
cd contracts
forge install
```

### 5.2 Deploy Contract
```bash
# Make sure FIBONACCI_PROGRAM_VKEY is set in .env
source ../.env

# Deploy to Sepolia (or your chosen network)
forge script script/Deploy.s.sol --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast --verify
```

**Expected Output:**
```
Deploying to network: sepolia
Using SP1 Verifier at: 0x3B6041173B80E77f038f3F2C0f9744f04837185e
Program VKey: 0x1234567890abcdef...

✅ Fibonacci contract deployed at: 0xContractAddress123...
Contract owner: 0xYourAddress...
Verifier address: 0x3B6041173B80E77f038f3F2C0f9744f04837185e
Program VKey: 0x1234567890abcdef...

🎉 Deployment completed!
Network: sepolia
Contract: 0xContractAddress123...
Block: 1234567

📝 Deployment info saved to deployment.env
```

### 5.3 Update .env with Contract Address
Add the deployed contract address to your .env:
```bash
FIBONACCI_CONTRACT_ADDRESS=0xContractAddress123...
```

## 🔗 Step 6: Verify Proof On-Chain

### 6.1 Using Cast (Command Line)
```bash
# Load the proof artifacts
PUBLIC_VALUES=$(cat script/artifacts/public_values_n10.bin | xxd -p -c 0)
PROOF_BYTES=$(cat script/artifacts/proof_groth16_n10.bin | xxd -p -c 0)

# Call the verification function
cast call $FIBONACCI_CONTRACT_ADDRESS \
  "verifyFibonacciProof(bytes,bytes)" \
  0x$PUBLIC_VALUES \
  0x$PROOF_BYTES \
  --rpc-url $RPC_URL
```

### 6.2 Using Web3 Interface
Create a simple frontend or use Etherscan:

```javascript
// Example Web3.js call
const contract = new web3.eth.Contract(ABI, contractAddress);
const result = await contract.methods.verifyFibonacciProof(
  publicValues,
  proofBytes
).call();

console.log('Verification result:', result);
// Expected: [10, 34, 55] // [n, fibonacci(n-1), fibonacci(n)]
```

## 📊 Step 7: Monitor and Test

### 7.1 Check Contract Events
```bash
# Watch for FibonacciVerified events
cast logs --address $FIBONACCI_CONTRACT_ADDRESS \
  --from-block latest \
  --rpc-url $RPC_URL
```

### 7.2 Query Contract State
```bash
# Check total proofs verified
cast call $FIBONACCI_CONTRACT_ADDRESS "totalProofsVerified()" --rpc-url $RPC_URL

# Check if a specific number was verified
cast call $FIBONACCI_CONTRACT_ADDRESS "verifiedNumbers(uint32)" 10 --rpc-url $RPC_URL

# Get Fibonacci result
cast call $FIBONACCI_CONTRACT_ADDRESS "getFibonacciResult(uint32)" 10 --rpc-url $RPC_URL
```

## 🔄 Step 8: Batch Operations

### 8.1 Generate Multiple Proofs
```bash
# Generate proofs for multiple inputs
for n in 5 10 15 20; do
  cargo run --release --bin network_evm -- --n $n --system groth16 --output_dir "artifacts_batch"
done
```

### 8.2 Batch Verify On-Chain
```bash
# Use the batchVerifyFibonacci function
cast send $FIBONACCI_CONTRACT_ADDRESS \
  "batchVerifyFibonacci(bytes[],bytes[])" \
  "[0x$PUBLIC_VALUES_1,0x$PUBLIC_VALUES_2]" \
  "[0x$PROOF_BYTES_1,0x$PROOF_BYTES_2]" \
  --private-key $PRIVATE_KEY \
  --rpc-url $RPC_URL
```

## 🐛 Troubleshooting

### Common Issues

**1. "Invalid proof" error:**
- Ensure VKey in contract matches the one from `vkey` command
- Check that proof was generated with the same program version
- Verify public values format

**2. "Insufficient funds" error:**
- Check ETH balance for gas fees
- Check SP1 network credits balance

**3. "Timeout" during proof generation:**
- Network proving can take 5-15 minutes
- Check network status: https://status.succinct.xyz
- Try again during off-peak hours

**4. Contract deployment fails:**
- Verify RPC URL is correct
- Check private key has sufficient ETH
- Ensure network name matches deployment script

### Useful Commands

```bash
# Check SP1 network balance
# (Add this to your script if needed)

# Check Ethereum balance
cast balance $YOUR_ADDRESS --rpc-url $RPC_URL

# Check contract is deployed correctly
cast code $FIBONACCI_CONTRACT_ADDRESS --rpc-url $RPC_URL

# Get transaction receipt
cast receipt $TX_HASH --rpc-url $RPC_URL
```

## 🎯 Next Steps

1. **Customize the Program**: Modify `program/src/main.rs` for your use case
2. **Enhance the Contract**: Add business logic to `contracts/src/Fibonacci.sol`
3. **Build Frontend**: Create a web interface for proof submission
4. **Scale**: Deploy to mainnet and implement production monitoring

## 📚 Additional Resources

- [SP1 Documentation](https://docs.succinct.xyz/)
- [SP1 Network Guide](https://docs.succinct.xyz/docs/network/developers/key-setup)
- [SP1 Contracts](https://github.com/succinctlabs/sp1-contracts)
- [Foundry Documentation](https://book.getfoundry.sh/)

## 🤝 Support

- [SP1 Discord](https://discord.gg/succinct)
- [GitHub Issues](https://github.com/succinctlabs/sp1/issues)
- [Documentation](https://docs.succinct.xyz/)

---

**🎉 Congratulations! You now have a complete SP1 on-chain verification setup!** 