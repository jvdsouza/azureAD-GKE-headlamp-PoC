Write-Host "`n🔍 Running SpecKit SDD diagnostics..." -ForegroundColor Cyan

# --- Configuration ---
$composeFile = "specify-compose.yaml"
$workspacePath = "C:\Users\jason\programming\azureAD-GKE-headlamp"
$kindPorts = @(6443, 6445, 4466, 4566, 7007, 7107, 5556)
$containers = @("spec-tests", "kind-cluster", "dex", "backstage", "headlamp")

# --- Step 1: Check for locked ports ---
Write-Host "`n⚙️ Checking for port conflicts..." -ForegroundColor Yellow
foreach ($port in $kindPorts) {
    $portUsed = netstat -ano | findstr ":$port"
    if ($portUsed) {
        Write-Host "   Port $port is in use. Releasing..." -ForegroundColor Red
        $pid = ($portUsed -split "\s+")[-1]
        if ($pid -match '^\d+$') {
            try {
                Stop-Process -Id $pid -Force -ErrorAction Stop
                Write-Host "   ✅ Released port $port (PID: $pid)" -ForegroundColor Green
            } catch {
                Write-Host "   ⚠️ Failed to stop process $pid (port $port)" -ForegroundColor Yellow
            }
        }
    } else {
        Write-Host "   Port $port is free." -ForegroundColor Green
    }
}

# --- Step 2: Remove old containers ---
Write-Host "`n🧹 Cleaning up stale containers..." -ForegroundColor Yellow
foreach ($container in $containers) {
    docker rm -f $container 2>$null | Out-Null
}
docker network prune -f | Out-Null

# --- Step 3: Clear BuildKit cache ---
Write-Host "`n🧼 Clearing Docker build cache..." -ForegroundColor Yellow
docker builder prune -af | Out-Null

# --- Step 4: Rebuild SpecKit stack ---
Write-Host "`n🔨 Rebuilding SpecKit stack..." -ForegroundColor Cyan
cd $workspacePath
docker compose -f $composeFile build --no-cache

# --- Step 5: Start the environment ---
Write-Host "`n🚀 Starting environment..." -ForegroundColor Cyan
docker compose -f $composeFile up -d

# --- Step 6: Health checks ---
Write-Host "`n🩺 Checking container health..." -ForegroundColor Cyan
foreach ($container in $containers) {
    $status = docker ps -a --format "{{.Names}}: {{.Status}}" | findstr $container
    if ($status) {
        Write-Host "   $status"
    } else {
        Write-Host "   ⚠️ $container not found!"
    }
}

Write-Host "`n✅ Diagnostics complete. If tests still fail, re-run with '--no-cache'." -ForegroundColor Green
