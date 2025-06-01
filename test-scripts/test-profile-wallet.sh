#!/bin/bash

API_URL="https://mcp-blocksleuth-production.up.railway.app"
ADDRESS="0xE8D848debB3A3e12AA815b15900c8E020B863F31"

echo "Testing profile_wallet_behavior tool directly..."
echo ""

# Get session
SESSION_ID=$(curl -s -N "$API_URL/sse" -H "Accept: text/event-stream" -m 2 2>&1 | grep -o '"sessionId":"[^"]*"' | cut -d'"' -f4 | head -1)
echo "Session ID: $SESSION_ID"
echo ""

# Test 1: profile_wallet_behavior with "ethereum"
echo "Test 1: profile_wallet_behavior with network name 'ethereum'..."
curl -X POST "$API_URL/message?sessionId=$SESSION_ID" \
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
  }" 2>&1

echo ""
echo ""

# Test 2: profile_wallet_behavior with "1"  
echo "Test 2: profile_wallet_behavior with chain ID '1'..."
curl -X POST "$API_URL/message?sessionId=$SESSION_ID" \
  -H "Content-Type: application/json" \
  -d "{
    \"jsonrpc\":\"2.0\",
    \"method\":\"tools/call\",
    \"params\":{
      \"name\":\"profile_wallet_behavior\",
      \"arguments\":{
        \"walletAddress\":\"$ADDRESS\",
        \"chainId\":\"1\"
      }
    },
    \"id\":2
  }" 2>&1

echo ""
echo ""
echo "✅ Tests completed"