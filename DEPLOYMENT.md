# MCP BlockSleuth Deployment Guide

This guide covers various deployment options for the MCP BlockSleuth server.

## Table of Contents
- [Prerequisites](#prerequisites)
- [Deployment Options](#deployment-options)
  - [Docker](#docker)
  - [Railway](#railway)
  - [Render](#render)
  - [Fly.io](#flyio)
  - [Google Cloud Run](#google-cloud-run)
  - [AWS ECS](#aws-ecs)
  - [VPS (Ubuntu/Debian)](#vps-ubuntudebian)

## Prerequisites

- Dune Analytics API key (required)
- Blockscout API access (no key needed)
- Node.js 18+ or Bun runtime

## Deployment Options

### Docker

The easiest way to deploy MCP BlockSleuth is using Docker.

1. **Build and run with Docker Compose:**
   ```bash
   # Create .env file with your API key
   echo "DUNE_API_KEY=your_api_key_here" > .env

   # Build and start the container
   docker-compose up -d
   ```

2. **Build and run manually:**
   ```bash
   # Build the image
   docker build -t mcp-blocksleuth .

   # Run the container
   docker run -d \
     -p 3456:3456 \
     -e DUNE_API_KEY=your_api_key_here \
     --name blocksleuth \
     mcp-blocksleuth
   ```

3. **Test the deployment:**
   ```bash
   curl http://localhost:3456/health
   ```

### Railway

Deploy to Railway with one click:

1. Fork this repository
2. Connect Railway to your GitHub account
3. Create new project from the forked repo
4. Add environment variable: `DUNE_API_KEY`
5. Deploy!

Railway will automatically detect the Dockerfile and deploy your service.

### Render

1. Fork this repository
2. Create a new Web Service on Render
3. Connect your GitHub repository
4. Configure:
   - Build Command: `bun install && bun run build`
   - Start Command: `bun run dist/src/index.js --transport sse --port $PORT`
   - Add environment variable: `DUNE_API_KEY`
5. Deploy!

### Fly.io

1. Install Fly CLI: `brew install flyctl`

2. Create `fly.toml`:
   ```toml
   app = "mcp-blocksleuth"
   primary_region = "iad"

   [build]
     dockerfile = "Dockerfile"

   [env]
     NODE_ENV = "production"
     TRANSPORT = "sse"

   [[services]]
     internal_port = 3456
     protocol = "tcp"

     [[services.ports]]
       port = 443
       handlers = ["tls", "http"]

     [[services.ports]]
       port = 80
       handlers = ["http"]

     [[services.http_checks]]
       interval = "30s"
       timeout = "10s"
       grace_period = "30s"
       method = "get"
       path = "/health"
   ```

3. Deploy:
   ```bash
   fly launch
   fly secrets set DUNE_API_KEY=your_api_key_here
   fly deploy
   ```

### Google Cloud Run

1. Install gcloud CLI and authenticate

2. Build and push to Container Registry:
   ```bash
   gcloud builds submit --tag gcr.io/YOUR_PROJECT_ID/mcp-blocksleuth
   ```

3. Deploy to Cloud Run:
   ```bash
   gcloud run deploy mcp-blocksleuth \
     --image gcr.io/YOUR_PROJECT_ID/mcp-blocksleuth \
     --platform managed \
     --allow-unauthenticated \
     --set-env-vars="DUNE_API_KEY=your_api_key_here" \
     --port 3456
   ```

### AWS ECS

1. Build and push to ECR:
   ```bash
   aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin YOUR_ECR_URI
   docker build -t mcp-blocksleuth .
   docker tag mcp-blocksleuth:latest YOUR_ECR_URI/mcp-blocksleuth:latest
   docker push YOUR_ECR_URI/mcp-blocksleuth:latest
   ```

2. Create ECS task definition with:
   - Image: YOUR_ECR_URI/mcp-blocksleuth:latest
   - Port mapping: 3456:3456
   - Environment variable: DUNE_API_KEY

3. Create ECS service with ALB for load balancing

### VPS (Ubuntu/Debian)

1. **Install dependencies:**
   ```bash
   # Install Bun
   curl -fsSL https://bun.sh/install | bash

   # Or install Node.js
   curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
   sudo apt-get install -y nodejs
   ```

2. **Clone and setup:**
   ```bash
   git clone https://github.com/crazyrabbitLTC/mcp-blocksleuth.git
   cd mcp-blocksleuth
   bun install
   bun run build
   ```

3. **Create systemd service:**
   ```bash
   sudo nano /etc/systemd/system/blocksleuth.service
   ```

   ```ini
   [Unit]
   Description=MCP BlockSleuth Server
   After=network.target

   [Service]
   Type=simple
   User=ubuntu
   WorkingDirectory=/home/ubuntu/mcp-blocksleuth
   ExecStart=/home/ubuntu/.bun/bin/bun run dist/src/index.js --transport sse --port 3456
   Restart=on-failure
   Environment="NODE_ENV=production"
   Environment="DUNE_API_KEY=your_api_key_here"

   [Install]
   WantedBy=multi-user.target
   ```

4. **Start the service:**
   ```bash
   sudo systemctl daemon-reload
   sudo systemctl enable blocksleuth
   sudo systemctl start blocksleuth
   ```

5. **Setup Nginx reverse proxy (optional):**
   ```nginx
   server {
       listen 80;
       server_name your-domain.com;

       location / {
           proxy_pass http://localhost:3456;
           proxy_http_version 1.1;
           proxy_set_header Upgrade $http_upgrade;
           proxy_set_header Connection 'upgrade';
           proxy_set_header Host $host;
           proxy_cache_bypass $http_upgrade;
           
           # SSE specific settings
           proxy_set_header Cache-Control no-cache;
           proxy_set_header X-Accel-Buffering no;
           proxy_read_timeout 86400;
       }
   }
   ```

## Environment Variables

- `DUNE_API_KEY` (required): Your Dune Analytics API key
- `PORT` (optional): Server port (default: 3456)
- `TRANSPORT` (optional): Transport mode - "sse" or "stdio" (default: stdio)

## Testing Your Deployment

Once deployed, test your server:

```bash
# Health check
curl https://your-deployment-url/health

# Establish SSE connection
curl -N https://your-deployment-url/sse

# Send a request (replace SESSION_ID)
curl -X POST https://your-deployment-url/message \
  -H "Content-Type: application/json" \
  -H "X-Session-Id: SESSION_ID" \
  -d '{"jsonrpc":"2.0","method":"tools/list","params":{},"id":1}'
```

## Security Considerations

1. **API Key Protection**: Never commit your DUNE_API_KEY to version control
2. **HTTPS**: Always use HTTPS in production deployments
3. **Rate Limiting**: Consider implementing rate limiting for public deployments
4. **CORS**: The server allows all origins by default. Restrict this in production if needed

## Monitoring

- Health endpoint: `/health`
- Monitor SSE connections and session count
- Set up alerts for high error rates or downtime
- Track API usage to stay within Dune Analytics limits

## Troubleshooting

1. **Port already in use**: Change the PORT environment variable
2. **SSE connection drops**: Check proxy/load balancer timeout settings
3. **API errors**: Verify DUNE_API_KEY is set correctly
4. **Memory issues**: Increase container/instance memory allocation

For more help, see the [main README](README.md) or open an issue on GitHub.