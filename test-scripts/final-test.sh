#!/bin/bash

API_URL="https://mcp-blocksleuth-production.up.railway.app"
ADDRESS="0xE8D848debB3A3e12AA815b15900c8E020B863F31"

echo "Testing MCP BlockSleuth chain ID mapping..."
echo ""

# Use a single curl session to maintain SSE connection
{
    # Connect and wait for session
    SESSION_ID=""
    while IFS= read -r line; do
        if [[ $line == data:* ]]; then
            if [[ $line == *"sessionId"* ]] && [ -z "$SESSION_ID" ]; then
                SESSION_ID=$(echo "$line" | grep -o '"sessionId":"[^"]*"' | cut -d'"' -f4 | head -1)
                echo "Connected with session: $SESSION_ID"
                echo ""
                
                # Send test request after getting session
                (
                    sleep 1
                    echo "Testing get_evm_balances with 'ethereum'..."
                    curl -s -X POST "$API_URL/message?sessionId=$SESSION_ID" \
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
                      }" > /dev/null
                    
                    sleep 2
                    
                    echo ""
                    echo "Testing profile_wallet_behavior with 'ethereum'..."
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
                        \"id\":2
                      }" > /dev/null
                ) &
            elif [[ $line == *"\"id\":1"* ]]; then
                echo "Response for get_evm_balances:"
                echo "$line" | sed 's/^data: //' | jq -r '.result.content[0].text // .result' 2>/dev/null | head -5
                echo ""
            elif [[ $line == *"\"id\":2"* ]]; then
                echo "Response for profile_wallet_behavior:"
                echo "$line" | sed 's/^data: //' | jq -r '.result.content[0].text // .result' 2>/dev/null | head -5
                echo ""
                # Exit after second response
                break
            fi
        fi
    done
} < <(curl -s -N "$API_URL/sse" -H "Accept: text/event-stream" --max-time 30)

echo "✅ Test completed"