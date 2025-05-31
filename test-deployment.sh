#!/bin/bash

# Replace with your actual Railway domain
DOMAIN="your-app.up.railway.app"

echo "Testing MCP BlockSleuth deployment..."
echo "Domain: https://$DOMAIN"
echo ""

# 1. Health check
echo "1. Health Check:"
curl -s https://$DOMAIN/health | jq .
echo ""

# 2. Establish SSE connection and get session ID
echo "2. Getting Session ID:"
SESSION_ID=$(curl -s -I https://$DOMAIN/sse | grep -i x-session-id | cut -d' ' -f2 | tr -d '\r')
echo "Session ID: $SESSION_ID"
echo ""

# 3. List available tools
echo "3. Listing Tools:"
curl -s -X POST https://$DOMAIN/message \
  -H "Content-Type: application/json" \
  -H "X-Session-Id: $SESSION_ID" \
  -d '{"jsonrpc":"2.0","method":"tools/list","params":{},"id":1}'
echo -e "\n"

# 4. Test a simple tool
echo "4. Testing Blockscout Ping:"
curl -s -X POST https://$DOMAIN/message \
  -H "Content-Type: application/json" \
  -H "X-Session-Id: $SESSION_ID" \
  -d '{"jsonrpc":"2.0","method":"tools/call","params":{"name":"ping_blockscout","arguments":{"network":"ethereum"}},"id":2}'
echo -e "\n"

echo "Test complete! Check SSE endpoint for actual responses."