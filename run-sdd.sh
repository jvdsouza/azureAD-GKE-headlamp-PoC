#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------
#  Spec Kit Starter PoC Runner (Headlamp + Backstage + Dex)
# ---------------------------------------------------------

COMPOSE_FILE="specify-compose.yaml"

echo "🚀 Starting Spec Kit PoC environment..."
docker compose -f "$COMPOSE_FILE" up -d --build

# Function to check health of a container
check_health() {
  local container=$1
  local status
  status=$(docker inspect --format='{{.State.Health.Status}}' "$container" 2>/dev/null || echo "unknown")
  echo "$status"
}

# Wait for all key containers to become healthy
wait_for_health() {
  local container=$1
  local retries=40
  local sleep_interval=10
  local attempt=1

  echo "🩺 Waiting for $container to become healthy..."
  while [[ $attempt -le $retries ]]; do
    status=$(check_health "$container")
    if [[ "$status" == "healthy" ]]; then
      echo "✅ $container is healthy!"
      return 0
    fi
    echo "⏳ ($attempt/$retries) $container is $status..."
    attempt=$((attempt + 1))
    sleep $sleep_interval
  done

  echo "❌ Timeout: $container did not become healthy."
  docker logs "$container" || true
  exit 1
}

# List of services to verify health
SERVICES=("dex" "kind-cluster" "backstage" "headlamp")

for service in "${SERVICES[@]}"; do
  wait_for_health "$service"
done

echo "🧪 Running test suite (pytest)..."
docker logs -f spec-tests || true

echo "📋 Checking test container exit code..."
exit_code=$(docker inspect spec-tests --format='{{.State.ExitCode}}' || echo 1)

if [[ "$exit_code" -eq 0 ]]; then
  echo "✅ All tests passed successfully!"
else
  echo "❌ Some tests failed. Inspect logs with:"
  echo "   docker logs spec-tests"
fi

# Stop and clean up containers
echo "🧹 Cleaning up..."
docker compose -f "$COMPOSE_FILE" down -v

echo "🏁 Done. Environment torn down cleanly."
