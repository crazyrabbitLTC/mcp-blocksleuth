#!/bin/bash

API_URL="https://mcp-blocksleuth-production.up.railway.app"
ADDRESS="0xE8D848debB3A3e12AA815b15900c8E020B863F31"

echo "Detailed testing of chain ID mapping on Railway..."
echo ""

# Create temp file for SSE output
SSE_OUTPUT=$(mktemp)
ERROR_LOG=$(mktemp)

# Start SSE connection in background
echo "Starting SSE connection..."
curl -s -N "$API_URL/sse" -H "Accept: text/event-stream" > "$SSE_OUTPUT" 2>"$ERROR_LOG" &
SSE_PID=$!

# Wait for connection
sleep 2

# Get session ID
SESSION_ID=$(grep -o '"sessionId":"[^"]*"' "$SSE_OUTPUT" | cut -d'"' -f4 | head -1)
echo "Session ID: $SESSION_ID"
echo ""

if [ -z "$SESSION_ID" ]; then
    echo "Failed to get session ID"
    cat "$ERROR_LOG"
    kill $SSE_PID 2>/dev/null
    rm -f "$SSE_OUTPUT" "$ERROR_LOG"
    exit 1
fi

# Function to monitor SSE and extract results
monitor_sse() {
    local request_id=$1
    local start_time=$(date +%s)
    local timeout=10
    
    while true; do
        local current_time=$(date +%s)
        local elapsed=$((current_time - start_time))
        
        if [ $elapsed -gt $timeout ]; then
            echo "Timeout waiting for response"
            break
        fi
        
        # Look for response with matching ID
        local response=$(grep -E "\"id\":$request_id" "$SSE_OUTPUT" | tail -1)
        if [ ! -z "$response" ]; then
            echo "$response" | jq -r '.result.content[0].text // .result' 2>/dev/null || echo "$response"
            break
        fi
        
        sleep 0.5
    done
}

# Test 1: Direct chainIds parameter (should fail with ethereum)
echo "=== Test 1: get_evm_balances with chainIds='ethereum' ==="
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
    \"id\":100
  }" > /dev/null

sleep 2
monitor_sse 100
echo ""

# Test 2: Using numeric chain ID (should work)
echo "=== Test 2: get_evm_balances with chainIds='1' ==="
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
    \"id\":101
  }" > /dev/null

sleep 2
monitor_sse 101 | head -20
echo ""

# Test 3: profile_wallet_behavior (should use helpers)
echo "=== Test 3: profile_wallet_behavior with chainId='ethereum' ==="
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
    \"id\":102
  }" > /dev/null

sleep 3
monitor_sse 102 | head -20
echo ""

# Clean up
kill $SSE_PID 2>/dev/null
rm -f "$SSE_OUTPUT" "$ERROR_LOG"

echo "✅ Testing completed"