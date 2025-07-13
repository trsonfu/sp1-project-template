# 🌐 Succinct RPC Configuration Guide

## Overview
Succinct provides dedicated RPC endpoints for both production and Sepolia testnet. Using Succinct's RPC is the recommended approach for SP1 projects.

## Available RPC Endpoints

### Sepolia Testnet (Recommended for Testing)
```bash
RPC_URL=https://rpc.sepolia.succinct.xyz
```

### Production Network
```bash
RPC_URL=https://rpc.production.succinct.xyz
```

## Benefits of Using Succinct's RPC

1. **Optimized for SP1**: Specially configured for SP1 operations
2. **No API Key Required**: No need to sign up for Infura/Alchemy
3. **Built-in Compatibility**: Tested and optimized for SP1 proof verification
4. **Reduced Latency**: Direct connection to Succinct's infrastructure
5. **Simplified Setup**: One less third-party service to configure

## Understanding RPC vs Etherscan API Key

### RPC URL (Required)
- **Purpose**: Deploy and interact with smart contracts
- **What it does**: Send transactions, call functions, query blockchain state
- **Succinct's RPC**: `https://rpc.sepolia.succinct.xyz`

### Etherscan API Key (Optional)
- **Purpose**: Verify contract source code on Etherscan
- **What it does**: Makes contracts readable/auditable on Etherscan
- **Required**: No - contracts work perfectly without verification
- **Benefits**: Users can read your contract code on Etherscan
- **Get key**: https://etherscan.io/apis

## Configuration

### For Sepolia Testing
```bash
# .env file
SP1_PROVER=network
NETWORK_PRIVATE_KEY=0x...
PRIVATE_KEY=0x...
RPC_URL=https://rpc.sepolia.succinct.xyz
ETHERSCAN_API_KEY=your_etherscan_key  # Optional - for contract verification
```

### For Production
```bash
# .env file
SP1_PROVER=network
NETWORK_PRIVATE_KEY=0x...
PRIVATE_KEY=0x...
RPC_URL=https://rpc.production.succinct.xyz
ETHERSCAN_API_KEY=your_etherscan_key  # Optional - for contract verification
```

## Alternative RPC Options

If you prefer to use other RPC providers:

### Infura
```bash
RPC_URL=https://sepolia.infura.io/v3/YOUR_PROJECT_ID
```

### Alchemy
```bash
RPC_URL=https://eth-sepolia.g.alchemy.com/v2/YOUR_API_KEY
```

### Public RPC (Not Recommended)
```bash
RPC_URL=https://sepolia.dev
```

## Network Selection

The RPC endpoints support different networks:

| Network | RPC URL | Purpose |
|---------|---------|---------|
| Sepolia | `https://rpc.sepolia.succinct.xyz` | Testing & Development |
| Mainnet | `https://rpc.production.succinct.xyz` | Production |

## Testing Connection

Test your RPC connection:

```bash
# Check connection
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
  https://rpc.sepolia.succinct.xyz

# Check balance
cast balance YOUR_ADDRESS --rpc-url https://rpc.sepolia.succinct.xyz
```

## Common Issues

1. **Connection Timeout**: Ensure firewall allows HTTPS connections
2. **Rate Limiting**: Succinct's RPC has reasonable rate limits for development
3. **Network Mismatch**: Ensure you're using the correct RPC for your target network

## Next Steps

1. Update your `.env` file with Succinct's RPC
2. Test the connection
3. Deploy your contracts
4. Generate and verify proofs

For more details, see the [ON_CHAIN_SETUP.md](ON_CHAIN_SETUP.md) guide. 