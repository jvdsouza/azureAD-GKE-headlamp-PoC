# Base: official Backstage container
FROM ghcr.io/backstage/backstage:1.44.1

WORKDIR /app

# Copy both the backend and frontend plugins into the correct locations
COPY headlamp-backend /app/plugins/headlamp-backend
COPY headlamp /app/plugins/headlamp

# Install dependencies
RUN cd /app/plugins/headlamp-backend && npm install --legacy-peer-deps
RUN cd /app/plugins/headlamp && npm install --legacy-peer-deps

# Optional: build if scripts are present
RUN mkdir -p /app/app
RUN cd /app/plugins/headlamp-backend && npm run build || true
RUN cd /app/plugins/headlamp && npm run build || true

# Expose Backstage port
EXPOSE 7007

# Start the Backstage backend
CMD ["node", "packages/backend", "--config", "app-config.yaml"]
