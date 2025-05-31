# MCP BlockSleuth Integration Guide

## Your Deployment Details

Once deployed on Railway, you'll have:
- **API URL**: `https://your-app.up.railway.app`
- **Health Check**: `https://your-app.up.railway.app/health`
- **SSE Endpoint**: `https://your-app.up.railway.app/sse`
- **Message Endpoint**: `https://your-app.up.railway.app/message`

## Integration Options

### 1. Claude Desktop (MCP Client)

Currently, Claude Desktop only supports stdio transport, not HTTP/SSE. For Claude Desktop integration, you'd need to run the server locally:

```json
{
  "mcpServers": {
    "blocksleuth": {
      "command": "node",
      "args": ["/path/to/mcp-blocksleuth/dist/src/index.js"],
      "env": {
        "DUNE_API_KEY": "your_api_key"
      }
    }
  }
}
```

### 2. Custom MCP Client (HTTP/SSE)

Your Railway deployment is perfect for custom MCP clients that support HTTP/SSE transport:

```javascript
// Example JavaScript client
const sessionId = await fetch('https://your-app.up.railway.app/sse')
  .then(res => res.headers.get('x-session-id'));

// Send requests
const response = await fetch('https://your-app.up.railway.app/message', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'X-Session-Id': sessionId
  },
  body: JSON.stringify({
    jsonrpc: '2.0',
    method: 'tools/call',
    params: {
      name: 'blockscout_search',
      arguments: {
        network: 'ethereum',
        query: '0xAddress...'
      }
    },
    id: 1
  })
});
```

### 3. Direct API Usage

You can also use the deployed server as a REST API:

```bash
# Get blockchain data
curl -X POST https://your-app.up.railway.app/message \
  -H "Content-Type: application/json" \
  -H "X-Session-Id: $SESSION_ID" \
  -d '{
    "jsonrpc": "2.0",
    "method": "tools/call",
    "params": {
      "name": "investigate_smart_contract",
      "arguments": {
        "contractAddress": "0x...",
        "network": "ethereum"
      }
    },
    "id": 1
  }'
```

## Available Tools

Your deployment provides 38+ blockchain analysis tools:

### Quick Examples:

1. **Check Wallet Balance**:
   ```json
   {
     "name": "get_evm_balances",
     "arguments": {
       "address": "0x...",
       "network": "ethereum"
     }
   }
   ```

2. **Investigate Token**:
   ```json
   {
     "name": "token_deep_analysis",
     "arguments": {
       "tokenAddress": "0x...",
       "network": "ethereum"
     }
   }
   ```

3. **Analyze Transaction**:
   ```json
   {
     "name": "analyze_transaction_impact",
     "arguments": {
       "txHash": "0x...",
       "network": "ethereum"
     }
   }
   ```

## Custom Domain (Optional)

To use a custom domain:
1. Add your domain in Railway Settings → Domains
2. Update your DNS with Railway's CNAME
3. Railway handles SSL automatically

## Monitoring

- Check deployment status: Railway dashboard
- View logs: Railway → Deployments → View Logs
- Monitor health: `curl https://your-app.up.railway.app/health`

## Rate Limits

Remember your Dune API has rate limits. Monitor usage in your Dune dashboard.

## Support

- Issues: https://github.com/crazyrabbitLTC/mcp-blocksleuth/issues
- Railway docs: https://docs.railway.app
- MCP docs: https://modelcontextprotocol.io