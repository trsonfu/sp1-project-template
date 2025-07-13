#!/bin/bash

echo "🔍 SP1 On-Chain Proof Verification"
echo "=================================="

# Set default values
CONTRACT_ADDRESS="${FIBONACCI_CONTRACT_ADDRESS:-0x44a4c90114d64A027DB4630639153DC54eaA6224}"
RPC_URL="${RPC_URL:-https://rpc.sepolia.succinct.xyz}"

echo "📝 Contract Address: $CONTRACT_ADDRESS"
echo "🌐 RPC URL: $RPC_URL"

# Check if contract call data exists
if [ ! -f "artifacts/contract_call_data_n10.json" ]; then
    echo "❌ Contract call data not found at artifacts/contract_call_data_n10.json"
    echo "   Please run: cargo run --release --bin network_evm -- --system plonk"
    exit 1
fi

echo "🔍 Reading contract call data..."

# Extract proof bytes and public values from JSON
PROOF_BYTES=$(jq -r '.parameters.proofBytes' artifacts/contract_call_data_n10.json)
PUBLIC_VALUES=$(jq -r '.parameters.publicValues' artifacts/contract_call_data_n10.json)

echo "📊 Proof bytes length: ${#PROOF_BYTES}"
echo "📊 Public values: $PUBLIC_VALUES"

# Get contract VKey
echo "🔍 Getting contract VKey..."
VKEY=$(cast call $CONTRACT_ADDRESS "getProgramVKey()" --rpc-url $RPC_URL)
echo "🔑 Contract VKey: $VKEY"

# Call verifyFibonacciProof
echo "🔍 Calling verifyFibonacciProof..."
echo "   This might take a moment..."

# Use cast to call the function
RESULT=$(cast call $CONTRACT_ADDRESS "verifyFibonacciProof(bytes,bytes)" "$PROOF_BYTES" "$PUBLIC_VALUES" --rpc-url $RPC_URL 2>&1)

if [[ $? -eq 0 ]]; then
    echo "✅ Contract call successful!"
    echo "📊 Raw result: $RESULT"
    
    # Parse the result - it should be 3 uint32 values
    # Convert hex to decimal
    N_HEX=$(echo $RESULT | cut -c3-66)
    A_HEX=$(echo $RESULT | cut -c67-130)
    B_HEX=$(echo $RESULT | cut -c131-194)
    
    N_DEC=$((16#${N_HEX:56}))
    A_DEC=$((16#${A_HEX:56}))
    B_DEC=$((16#${B_HEX:56}))
    
    echo "📊 Decoded results:"
    echo "   n: $N_DEC"
    echo "   Fibonacci($(($N_DEC - 1))) = $A_DEC"
    echo "   Fibonacci($N_DEC) = $B_DEC"
    
    # Verify the math
    if [ $N_DEC -eq 10 ] && [ $A_DEC -eq 55 ] && [ $B_DEC -eq 89 ]; then
        echo "🎉 Mathematics verified correctly!"
        echo "   Fibonacci(9) = 55 ✓"
        echo "   Fibonacci(10) = 89 ✓"
        echo ""
        echo "🎊 SUCCESS: Real PLONK proof verified on-chain!"
    else
        echo "⚠️  Unexpected values returned"
    fi
else
    echo "❌ Contract call failed!"
    echo "   Error: $RESULT"
    echo "   This might be due to:"
    echo "   - Invalid proof data"
    echo "   - Wrong program VKey"
    echo "   - Contract not properly deployed"
    echo "   - Network issues"
fi 