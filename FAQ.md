# ❓ Frequently Asked Questions

## Environment Setup Questions

### Q: Why do I need 2 private keys? I already have one with Sepolia ETH!

**A:** They serve completely different purposes:

- **NETWORK_PRIVATE_KEY**: For SP1 Prover Network (Succinct's internal system)
  - Purpose: Authenticate and pay for proof generation
  - Needs: SP1 network credits (not ETH)
  - System: Succinct's internal network

- **PRIVATE_KEY**: For Ethereum blockchain
  - Purpose: Deploy contracts and send transactions
  - Needs: Sepolia ETH for gas fees  
  - System: Ethereum Sepolia network
  - This is: The one you already have!

### Q: Can I use the same private key for both?

**A:** Technically yes, but NOT recommended:
- Security risk: Using same key for different systems
- Different purposes: One for SP1 network, one for Ethereum
- Different requirements: One needs SP1 credits, one needs ETH

### Q: Do I need Infura or Alchemy API key?

**A:** No! Use Succinct's RPC: `https://rpc.sepolia.succinct.xyz`
- No API key required
- Optimized for SP1 operations
- Direct connection to Succinct's infrastructure

### Q: Is Etherscan API key required?

**A:** No, it's optional:
- **Without it**: Contracts deploy and work perfectly
- **With it**: Contracts become readable/auditable on Etherscan
- **Purpose**: Only for contract verification, not functionality

## Proof Generation Questions

### Q: What's the difference between local and network proving?

**A:** 
- **Local proving**: Uses your computer's resources (slower, limited)
- **Network proving**: Uses Succinct's powerful infrastructure (faster, scalable)
- **Recommendation**: Always use network proving for real applications

### Q: How much does network proving cost?

**A:** Check current pricing at https://docs.succinct.xyz/docs/network/developers/pricing
- Pay per proof generation
- Much cheaper than running your own infrastructure
- Credits can be purchased with crypto

### Q: Can I test locally first?

**A:** Yes! Use `SP1_PROVER=local` for development:
```bash
# Local testing (no network key needed)
SP1_PROVER=local cargo run --bin prove

# Network proving (requires NETWORK_PRIVATE_KEY)
SP1_PROVER=network cargo run --bin network_evm
```

## Contract Deployment Questions

### Q: Which networks are supported?

**A:** Multiple networks supported:
- **Sepolia**: `https://rpc.sepolia.succinct.xyz` (testing)
- **Mainnet**: `https://rpc.production.succinct.xyz` (production)
- **Base, Arbitrum**: Also supported

### Q: How do I get Sepolia ETH?

**A:** Use faucets:
- https://sepoliafaucet.com/
- https://faucet.quicknode.com/ethereum/sepolia
- https://www.alchemy.com/faucets/ethereum-sepolia

### Q: Why is my contract deployment failing?

**A:** Common issues:
1. **Insufficient ETH**: Check balance with `cast balance`
2. **Wrong RPC**: Ensure using correct RPC URL
3. **Wrong private key**: Verify PRIVATE_KEY has ETH
4. **Network mismatch**: Check NETWORK environment variable

## Verification Questions

### Q: How do I verify my proof on-chain?

**A:** After deployment:
1. Generate proof: `cargo run --bin network_evm`
2. Deploy contract: `forge script Deploy.s.sol --broadcast`
3. Verify proof: Use generated artifacts to call contract

### Q: What files are generated?

**A:** Key files:
- `proof.json`: The generated proof
- `public_values.json`: Public inputs/outputs
- `vkey.json`: Verification key
- Contract artifacts in `contracts/out/`

### Q: How do I know if verification worked?

**A:** Check contract events:
```bash
# Check if proof was verified
cast call $CONTRACT_ADDRESS "totalProofsVerified()" --rpc-url $RPC_URL

# Check specific result
cast call $CONTRACT_ADDRESS "getFibonacciResult(uint32)" 10 --rpc-url $RPC_URL
```

## Troubleshooting

### Q: "Network private key not whitelisted" error

**A:** Your NETWORK_PRIVATE_KEY needs approval:
1. Visit https://network.succinct.xyz
2. Request whitelist access
3. Wait for approval
4. Fund account with credits

### Q: "Insufficient funds" error

**A:** Check which type of funds:
- **For proof generation**: Need SP1 network credits
- **For contract deployment**: Need Sepolia ETH
- **Check balance**: `cast balance YOUR_ADDRESS --rpc-url $RPC_URL`

### Q: RPC connection issues

**A:** Test connection:
```bash
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
  https://rpc.sepolia.succinct.xyz
```

## Still Need Help?

1. Check the [ENV_GUIDE.md](ENV_GUIDE.md) for detailed environment setup
2. Review [ON_CHAIN_SETUP.md](ON_CHAIN_SETUP.md) for step-by-step guide
3. Visit [SP1 Documentation](https://docs.succinct.xyz)
4. Join [Succinct Discord](https://discord.gg/succinct) for community support 