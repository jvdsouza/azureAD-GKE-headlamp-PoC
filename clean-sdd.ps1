Write-Host "🧹 Cleaning up previous Spec Kit environment..." -ForegroundColor Yellow

# Stop and remove the Compose stack (ignore errors)
try {
    docker compose -f specify-compose.yaml down -v
} catch {
    Write-Host "No existing compose stack found."
}

# Remove leftover containers by name
$containers = @("kind-cluster", "dex", "backstage", "headlamp", "spec-tests")
foreach ($c in $containers) {
    if (docker ps -a --format '{{.Names}}' | Select-String -Pattern $c) {
        Write-Host "Removing old container: $c"
        docker rm -f $c | Out-Null
    }
}

# Optional: remove any dangling images to save space
docker image prune -f | Out-Null

Write-Host "✅ Cleanup complete. Fresh start ready." -ForegroundColor Green
