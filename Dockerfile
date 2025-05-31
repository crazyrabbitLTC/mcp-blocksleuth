# Build stage
FROM oven/bun:1.1.42-alpine AS builder

WORKDIR /app

# Copy package files
COPY package.json bun.lockb* ./

# Install dependencies
RUN bun install --frozen-lockfile

# Copy source code
COPY . .

# Build the TypeScript project
RUN bun run build

# Runtime stage
FROM oven/bun:1.1.42-alpine

WORKDIR /app

# Copy built files and dependencies
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./

# Make sure the built files are executable
RUN chmod -R 755 /app/dist

# Expose port (default 3456)
EXPOSE 3456

# Set default environment variables
ENV NODE_ENV=production
ENV TRANSPORT=sse
ENV PORT=3456

# Run the server with debugging for all env vars
CMD ["sh", "-c", "sleep 5 && echo 'All environment variables:' && env | sort && echo '---' && bun dist/src/index.js --transport ${TRANSPORT} --port ${PORT}"]
