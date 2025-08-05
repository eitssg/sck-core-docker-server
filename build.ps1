param(
    [switch]$NoCache
)

try {
    # Build first
    if ($NoCache) {
        Write-Host "Building with --no-cache..." -ForegroundColor Yellow
        docker build --no-cache --progress=plain -t sck-core-server .
    } else {
        Write-Host "Building with cache..." -ForegroundColor Green
        docker build --progress=plain -t sck-core-server .
    }
    
    if ($LASTEXITCODE -ne 0) {
        throw "Docker build failed"
    }
    
    # Then start services
    Write-Host "Starting services..." -ForegroundColor Green
    docker compose up
    
} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}