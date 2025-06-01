#!/bin/bash

API_URL="https://mcp-blocksleuth-production.up.railway.app"

echo "Simple chain ID test..."
echo ""

# Get a session and test in one curl command with SSE
curl -N "$API_URL/sse" -H "Accept: text/event-stream" 2>/dev/null | while IFS= read -r line; do
    if [[ $line == *"sessionId"* ]]; then
        SESSION_ID=$(echo "$line" | grep -o '"sessionId":"[^"]*"' | cut -d'"' -f4)
        echo "Got session: $SESSION_ID"
        
        # Test with ethereum network name
        echo ""
        echo "Testing with 'ethereum'..."
        curl -s -X POST "$API_URL/message?sessionId=$SESSION_ID" \
          -H "Content-Type: application/json" \
          -d '{
            "jsonrpc":"2.0",
            "method":"tools/call",
            "params":{
              "name":"get_evm_balances",
              "arguments":{
                "walletAddress":"0xE8D848debB3A3e12AA815b15900c8E020B863F31",
                "chainIds":"ethereum"
              }
            },
            "id":1
          }'
        break
    fi
done &

# Let it run for a bit then check results
sleep 10
echo ""
echo "Check Railway logs at: https://railway.app/project/*/service/*/logs"
echo "✅ Test sent"