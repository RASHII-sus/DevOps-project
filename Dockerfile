# Use Node.js 18 Alpine (small image ~180MB vs ~900MB full)
FROM node:18-alpine

# Set working directory inside container
WORKDIR /app

# Copy package files first (layer caching — only re-runs npm install if package.json changes)
COPY package*.json ./

# Install only production dependencies
RUN npm install --omit=dev

# Copy rest of application code
COPY . .

# Expose port the app listens on
EXPOSE 3000

# Health check so Kubernetes knows container is ready
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget -qO- http://localhost:3000/health || exit 1

# Run as non-root user for security
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser

# Start the application
CMD ["node", "server.js"]
