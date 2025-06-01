#!/bin/bash

API_URL="https://mcp-blocksleuth-production.up.railway.app"
ADDRESS="0xE8D848debB3A3e12AA815b15900c8E020B863F31"

echo "Testing MCP BlockSleuth prompts..."
echo ""

# Start SSE connection
SSE_OUTPUT=$(mktemp)
curl -s -N "$API_URL/sse" -H "Accept: text/event-stream" > "$SSE_OUTPUT" &
SSE_PID=$!

# Wait for session ID
sleep 2
SESSION_ID=$(grep -o '"sessionId":"[^"]*"' "$SSE_OUTPUT" | cut -d'"' -f4 | head -1)
echo "Session ID: $SESSION_ID"
echo ""

# Test comprehensive wallet analysis prompt
echo "Testing comprehensive_wallet_analysis prompt with 'ethereum' network..."
curl -s -X POST "$API_URL/message?sessionId=$SESSION_ID" \
  -H "Content-Type: application/json" \
  -d "{
    \"jsonrpc\":\"2.0\",
    \"method\":\"prompts/get\",
    \"params\":{
      \"name\":\"comprehensive_wallet_analysis\",
      \"arguments\":{
        \"walletAddress\":\"$ADDRESS\",
        \"chainId\":\"ethereum\"
      }
    },
    \"id\":1
  }" | jq '.'

echo ""

# Wait and check SSE
sleep 3
echo "Recent SSE events:"
tail -30 "$SSE_OUTPUT" | grep -E "data:" | tail -5

# Clean up
kill $SSE_PID 2>/dev/null
rm -f "$SSE_OUTPUT"

echo ""
echo "✅ Test completed"