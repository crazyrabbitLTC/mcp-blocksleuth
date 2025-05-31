#!/bin/bash

DOMAIN="https://mcp-blocksleuth-production.up.railway.app"

echo "Testing MCP BlockSleuth on Railway..."
echo ""

# Test 1: Establish SSE connection
echo "1. Getting session ID..."
SESSION_ID=$(curl -s -I "$DOMAIN/sse" -H "Accept: text/event-stream" | grep -i "x-session-id:" | awk '{print $2}' | tr -d '\r\n')
echo "Session ID: $SESSION_ID"
echo ""

if [ -z "$SESSION_ID" ]; then
    echo "Failed to get session ID. Trying alternative method..."
    # Start SSE connection in background
    curl -N "$DOMAIN/sse" -H "Accept: text/event-stream" > sse_output.txt 2>&1 &
    SSE_PID=$!
    sleep 2
    kill $SSE_PID 2>/dev/null
    SESSION_ID=$(grep -o '"sessionId":"[^"]*"' sse_output.txt | cut -d'"' -f4 | head -1)
    rm -f sse_output.txt
    echo "Session ID (attempt 2): $SESSION_ID"
fi

# Test 2: List tools
echo "2. Listing available tools..."
curl -X POST "$DOMAIN/message" \
  -H "Content-Type: application/json" \
  -H "X-Session-Id: $SESSION_ID" \
  -d '{"jsonrpc":"2.0","method":"tools/list","params":{},"id":1}' \
  -w "\nStatus: %{http_code}\n"

echo -e "\n"

# Test 3: Test Blockscout (no API key needed)
echo "3. Testing Blockscout ping (no API key required)..."
curl -X POST "$DOMAIN/message" \
  -H "Content-Type: application/json" \
  -H "X-Session-Id: $SESSION_ID" \
  -d '{"jsonrpc":"2.0","method":"tools/call","params":{"name":"ping_blockscout","arguments":{"network":"ethereum"}},"id":2}' \
  -w "\nStatus: %{http_code}\n"