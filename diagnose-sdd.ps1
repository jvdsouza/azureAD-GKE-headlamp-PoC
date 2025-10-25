#requires -Version 5.1
Clear-Host
Write-Host "🩺 Starting SpecKit Diagnostic Workflow..." -ForegroundColor Cyan

# --- Config ---
$composeFile = "specify-compose.yaml"
$services = @("kind", "dex", "headlamp", "backstage", "spec-tests")

function Check-Service {
    param([string]$service)
    Write-Host "`n🔍 Checking logs for $service..." -ForegroundColor Yellow
    docker compose -f $composeFile logs --tail 20 $service
}

function Wait-Service {
    param([string]$service, [int]$timeout = 120)
    Write-Host "⏳ Waiting for $service to become healthy (timeout $timeout s)..." -ForegroundColor DarkCyan
    $elapsed = 0
    while ($elapsed -lt $timeout) {
        $health = docker inspect --format "{{.State.Health.Status}}" "$((docker compose -f $composeFile ps -q $service))" 2>$null
        if ($health -eq "healthy") {
            Write-Host "✅ $service is healthy!" -ForegroundColor Green
            return
        }
        Start-Sleep -Seconds 5
        $elapsed += 5
    }
    Write-Host "❌ $service failed to become healthy in $timeout seconds." -ForegroundColor Red
    Check-Service $service
    throw "Service $service unhealthy"
}

Write-Host "`n🧹 Cleaning up old environment..." -ForegroundColor DarkGray
docker compose -f $composeFile down -v --remove-orphans | Out-Null
docker ps -a --format "{{.Names}}" | findstr "spec-kit" | ForEach-Object { docker rm -f $_ } 2>$null | Out-Null

Write-Host "`n🚀 Rebuilding environment..." -ForegroundColor Cyan
docker compose -f $composeFile build | Out-Null

# Step-by-step startup
foreach ($svc in $services) {
    Write-Host "`n=====================" -ForegroundColor Gray
    Write-Host "▶️  Starting service: $svc" -ForegroundColor Magenta
    Write-Host "=====================" -ForegroundColor Gray
    docker compose -f $composeFile up -d $svc | Out-Null
    Start-Sleep -Seconds 3

    if ($svc -eq "dex") { Wait-Service "dex" 90 }
    elseif ($svc -eq "kind") { Start-Sleep -Seconds 60 } # Kind can take longer
    elseif ($svc -eq "spec-tests") {
        Write-Host "🧪 Running SpecKit tests..." -ForegroundColor Cyan
        docker logs -f (docker compose -f $composeFile ps -q spec-tests)
    } else {
        Start-Sleep -Seconds 10
        Check-Service $svc
    }
}

Write-Host "`n🏁 Diagnostics complete. Review logs above for details." -ForegroundColor Cyan
