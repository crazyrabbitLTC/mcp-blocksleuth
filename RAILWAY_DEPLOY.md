# Railway Deployment Guide for MCP BlockSleuth

## Quick Deploy Steps

### 1. Push to GitHub
First, make sure your code is pushed to GitHub:
```bash
git add .
git commit -m "Add Railway deployment configuration"
git push origin main
```

### 2. Deploy on Railway

1. **Go to Railway Dashboard**
   - Visit https://railway.app/dashboard
   - Click "New Project"

2. **Deploy from GitHub**
   - Select "Deploy from GitHub repo"
   - Connect your GitHub account if not already connected
   - Search for and select `mcp-blocksleuth`
   - Select the branch to deploy (usually `main`)

**IMPORTANT**: Railway might auto-detect Node.js and use Nixpacks. Make sure it uses our Dockerfile:
- After deployment starts, if you see Nixpacks in the build logs:
  - Go to Settings → Build → Builder
  - Change from "Nixpacks" to "Dockerfile"
  - Redeploy

3. **Configure Environment Variables**
   Railway will automatically detect the Dockerfile. Now add your environment variables:
   
   - Click on your deployed service
   - Go to "Variables" tab
   - Click "New Variable"
   - Add these variables:
     ```
     DUNE_API_KEY=your_dune_api_key_here
     PORT=${{PORT}}
     TRANSPORT=sse
     NODE_ENV=production
     ```
   
   **Important**: Use `${{PORT}}` for the PORT variable - Railway will automatically assign a port.

4. **Deploy**
   - Railway will automatically start building and deploying
   - You can watch the build logs in real-time
   - The deployment typically takes 2-3 minutes

### 3. Get Your Deployment URL

Once deployed:
1. Go to your service in Railway
2. Click on "Settings" tab
3. Under "Domains", click "Generate Domain"
4. You'll get a URL like: `mcp-blocksleuth-production.up.railway.app`

### 4. Test Your Deployment

Test the deployment with these commands:

```bash
# Check health
curl https://your-app.up.railway.app/health

# Test SSE connection
curl -N https://your-app.up.railway.app/sse

# Get session ID from the response headers, then test a tool
curl -X POST https://your-app.up.railway.app/message \
  -H "Content-Type: application/json" \
  -H "X-Session-Id: YOUR_SESSION_ID" \
  -d '{"jsonrpc":"2.0","method":"tools/list","params":{},"id":1}'
```

## Environment Variables Reference

| Variable | Required | Description | Railway Value |
|----------|----------|-------------|---------------|
| DUNE_API_KEY | Yes | Your Dune Analytics API key | Your actual key |
| PORT | Yes | Server port | `${{PORT}}` |
| TRANSPORT | Yes | Transport mode | `sse` |
| NODE_ENV | No | Environment | `production` |

## Troubleshooting

### Build Fails
- Check the build logs in Railway dashboard
- Ensure all files are committed to Git
- Verify the Dockerfile syntax

### Server Won't Start
- Check runtime logs in Railway dashboard
- Verify DUNE_API_KEY is set correctly
- Ensure PORT is set to `${{PORT}}`

### SSE Connection Issues
- Railway supports SSE/WebSocket connections
- No special configuration needed
- If issues persist, check the runtime logs

### Health Check Fails
- The health endpoint should return 200 OK
- Check that the server is starting correctly
- Verify all environment variables are set

## Monitoring

Railway provides:
- Real-time logs
- Resource usage metrics
- Automatic restarts on failure
- Built-in SSL certificates

## Updating Your Deployment

To update your deployment:
1. Make changes locally
2. Commit and push to GitHub
3. Railway will automatically redeploy

```bash
git add .
git commit -m "Update feature X"
git push origin main
```

## Custom Domain (Optional)

To use a custom domain:
1. Go to Settings → Domains
2. Add your custom domain
3. Update your DNS records as instructed
4. Railway handles SSL automatically

## Cost Estimation

Railway's pricing:
- $5/month credit included (usually enough for this service)
- Pay for what you use beyond that
- This service typically uses minimal resources

## Next Steps

After deployment:
1. Test all endpoints thoroughly
2. Monitor logs for any errors
3. Set up alerts if needed
4. Share your deployment URL with MCP clients

Your MCP BlockSleuth server is now live and accessible from anywhere!