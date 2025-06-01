#!/bin/bash

API_URL="https://mcp-blocksleuth-production.up.railway.app"
ADDRESS="0xE8D848debB3A3e12AA815b15900c8E020B863F31"

echo "Testing chain ID mapping fix..."
echo ""

# Get session
SESSION_ID=$(curl -s -N "$API_URL/sse" -H "Accept: text/event-stream" -m 2 2>&1 | grep -o '"sessionId":"[^"]*"' | cut -d'"' -f4 | head -1)
echo "Session ID: $SESSION_ID"
echo ""

# Test 1: Using network name "ethereum"
echo "Test 1: Testing with network name 'ethereum'..."
curl -s -X POST "$API_URL/message?sessionId=$SESSION_ID" \
  -H "Content-Type: application/json" \
  -d "{
    \"jsonrpc\":\"2.0\",
    \"method\":\"tools/call\",
    \"params\":{
      \"name\":\"profile_wallet_behavior\",
      \"arguments\":{
        \"walletAddress\":\"$ADDRESS\",
        \"chainId\":\"ethereum\"
      }
    },
    \"id\":1
  }" | jq -r '.status'

echo ""

# Test 2: Using chain ID "1"
echo "Test 2: Testing with chain ID '1'..."
curl -s -X POST "$API_URL/message?sessionId=$SESSION_ID" \
  -H "Content-Type: application/json" \
  -d "{
    \"jsonrpc\":\"2.0\",
    \"method\":\"tools/call\",
    \"params\":{
      \"name\":\"get_evm_balances\",
      \"arguments\":{
        \"address\":\"$ADDRESS\",
        \"network\":\"1\"
      }
    },
    \"id\":2
  }" | jq -r '.status'

echo ""
echo "✅ Both tests submitted. The actual responses are in the SSE stream."