$ErrorActionPreference = "Stop"

# Port conflict guard — active in Workshop sandbox, skipped elsewhere
if (-not $env:APP_PORT) { $env:APP_PORT = "8501" }

# Startup timing
$T0 = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
function elapsed { [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds() - $script:T0 }

# Skip sync if lockfile unchanged (fast restart)
$uvHash = (Get-FileHash -Algorithm MD5 uv.lock -ErrorAction SilentlyContinue).Hash
$hashFile = ".venv/.uv-hash-$uvHash"
if ($uvHash -and -not (Test-Path $hashFile)) {
    Write-Host "[+$(elapsed)ms] uv sync starting..."
    uv sync --compile-bytecode --frozen
    if ($LASTEXITCODE -ne 0) { uv sync --compile-bytecode }
    Remove-Item .venv/.uv-hash-* -ErrorAction SilentlyContinue
    New-Item -ItemType File -Path $hashFile -Force | Out-Null
    Write-Host "[+$(elapsed)ms] uv sync done"
} else {
    Write-Host "[+$(elapsed)ms] uv sync skipped (lockfile unchanged)"
}

Write-Host "[+$(elapsed)ms] Starting Streamlit app on http://localhost:$($env:APP_PORT)"
uv run streamlit run app.py --server.port=$env:APP_PORT --server.headless=true
