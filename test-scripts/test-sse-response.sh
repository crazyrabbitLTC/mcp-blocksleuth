#!/bin/bash

API_URL="https://mcp-blocksleuth-production.up.railway.app"
ADDRESS="0xE8D848debB3A3e12AA815b15900c8E020B863F31"

echo "Testing MCP BlockSleuth with SSE response monitoring..."
echo ""

# Start SSE connection and capture session ID
echo "Connecting to SSE endpoint..."
SSE_OUTPUT=$(mktemp)
curl -s -N "$API_URL/sse" -H "Accept: text/event-stream" > "$SSE_OUTPUT" &
SSE_PID=$!

# Wait for session ID
sleep 2
SESSION_ID=$(grep -o '"sessionId":"[^"]*"' "$SSE_OUTPUT" | cut -d'"' -f4 | head -1)
echo "Session ID: $SESSION_ID"
echo ""

# Test with network name
echo "Testing with network name 'ethereum'..."
RESPONSE=$(curl -s -X POST "$API_URL/message?sessionId=$SESSION_ID" \
  -H "Content-Type: application/json" \
  -d "{
    \"jsonrpc\":\"2.0\",
    \"method\":\"tools/call\",
    \"params\":{
      \"name\":\"get_evm_balances\",
      \"arguments\":{
        \"walletAddress\":\"$ADDRESS\",
        \"chainIds\":\"ethereum\"
      }
    },
    \"id\":1
  }")

echo "Direct response: $RESPONSE"
echo ""

# Wait for SSE response
echo "Waiting for SSE response..."
sleep 3

# Check SSE output
echo "SSE Events received:"
tail -20 "$SSE_OUTPUT" | grep -E "data:|error:" | head -10
echo ""

# Test with chain ID
echo "Testing with chain ID '1'..."
RESPONSE2=$(curl -s -X POST "$API_URL/message?sessionId=$SESSION_ID" \
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
  }")

echo "Direct response: $RESPONSE2"
echo ""

# Clean up
kill $SSE_PID 2>/dev/null
rm -f "$SSE_OUTPUT"

echo "✅ Test completed"