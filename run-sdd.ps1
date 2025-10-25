# --------------------------------------------
# Spec Kit PoC Runner (Headlamp + Backstage + Dex)
# Windows PowerShell 7+ version (UTF-8 with BOM)
# --------------------------------------------

$ErrorActionPreference = "Stop"
$composeFile = "specify-compose.yaml"
$logDir = "logs"

# Optional: start logging (creates logs/run-YYYY-MM-DD_HH-mm-ss.log)
if (!(Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir | Out-Null }
$logFile = "$logDir/run-$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss').log"
Start-Transcript -Path $logFile -Force | Out-Null

function Write-Color {
    param([string]$Text, [ConsoleColor]$Color = "White")
    $old = $Host.UI.RawUI.ForegroundColor
    $Host.UI.RawUI.ForegroundColor = $Color
    Write-Host $Text
    $Host.UI.RawUI.ForegroundColor = $old
}

Write-Color "🚀 Starting Spec Kit PoC environment..." Cyan
docker compose -f $composeFile up -d --build

# Helper: return container health (safe even if no Health key)
function Get-ContainerHealth {
    param($Container)
    try {
        $health = docker inspect --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' $Container
        return $health
    }
    catch {
        return "unknown"
    }
}

# Wait for a container to become healthy
function Wait-ForHealth {
    param(
        [string]$Container,
        [int]$MaxRetries = 40,
        [int]$SleepSeconds = 10
    )

    Write-Color "🩺 Waiting for $Container to become healthy..." Yellow
    for ($i = 1; $i -le $MaxRetries; $i++) {
        $status = Get-ContainerHealth $Container
        if ($status -eq "healthy") {
            Write-Color "✅ $Container is healthy!" Green
            return
        } elseif ($status -eq "none") {
            Write-Color "⚠️  $Container has no healthcheck (skipping)" DarkYellow
            return
        }
        Write-Color "⏳ ($i/$MaxRetries) $Container is $status..." Gray
        Start-Sleep -Seconds $SleepSeconds
    }

    Write-Color "❌ Timeout: $Container did not become healthy." Red
    docker logs $Container | Out-String | Write-Host
    exit 1
}

# Containers to verify (skip those without healthchecks if needed)
$services = @("dex", "backstage", "headlamp")
foreach ($svc in $services) {
    Wait-ForHealth $svc
}

Write-Color "🧪 Running test suite (pytest)..." Cyan
docker logs -f spec-tests

Write-Color "📋 Checking test container exit code..." Cyan
$exitCode = docker inspect spec-tests --format='{{.State.ExitCode}}' 2>$null

if ($exitCode -eq 0) {
    Write-Color "✅ All tests passed successfully!" Green
} else {
    Write-Color "❌ Some tests failed. Check with: docker logs spec-tests" Red
}

# Write-Color "🧹 Cleaning up..." Yellow
# docker compose -f $composeFile down -v

# Write-Color "🏁 Done. Environment torn down cleanly." Green

Stop-Transcript | Out-Null
