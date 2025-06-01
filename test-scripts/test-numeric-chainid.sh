#!/bin/bash

API_URL="https://mcp-blocksleuth-production.up.railway.app"
ADDRESS="0xE8D848debB3A3e12AA815b15900c8E020B863F31"

echo "Testing get_evm_balances with numeric chain ID '1'..."
echo ""

# Get session
SESSION_ID=$(curl -s -N "$API_URL/sse" -H "Accept: text/event-stream" -m 2 2>&1 | grep -o '"sessionId":"[^"]*"' | cut -d'"' -f4 | head -1)
echo "Session ID: $SESSION_ID"
echo ""

# Create a background SSE listener to capture the response
SSE_OUTPUT=$(mktemp)
curl -s -N "$API_URL/sse" -H "Accept: text/event-stream" > "$SSE_OUTPUT" &
SSE_PID=$!
sleep 1

# Test with numeric chain ID "1"
echo "Sending request with chainIds='1'..."
curl -s -X POST "$API_URL/message?sessionId=$SESSION_ID" \
  -H "Content-Type: application/json" \
  -d "{
    \"jsonrpc\":\"2.0\",
    \"method\":\"tools/call\",
    \"params\":{
      \"name\":\"get_evm_balances\",
      \"arguments\":{
        \"walletAddress\":\"$ADDRESS\",
        \"chainIds\":\"1\"
      }
    },
    \"id\":1
  }"

echo ""
echo "Waiting for response..."
sleep 5

# Extract and display the response
echo ""
echo "Response:"
grep -E "\"id\":1" "$SSE_OUTPUT" | tail -1 | sed 's/^data: //' | jq '.result.content[0].text' -r 2>/dev/null | jq '.' 2>/dev/null || grep -E "\"id\":1" "$SSE_OUTPUT" | tail -1

# Clean up
kill $SSE_PID 2>/dev/null
rm -f "$SSE_OUTPUT"

echo ""
echo "✅ Test completed"