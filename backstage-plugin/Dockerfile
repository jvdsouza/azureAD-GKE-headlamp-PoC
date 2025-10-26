# Base image — plain Node instead of Backstage
FROM node:20-bullseye

# Set working directory
WORKDIR /app

# Copy plugin source
COPY headlamp-backend /app

# Install dependencies (use npm, not yarn)
RUN npm install --legacy-peer-deps

# Optional build step if script exists
RUN npm run build || true

# Expose port for Backstage backend
EXPOSE 7007

# Run plugin backend directly
CMD ["npm", "start"]
