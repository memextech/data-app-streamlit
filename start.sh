#!/bin/bash
set -e

# Port conflict guard — active in Workshop sandbox, skipped elsewhere
APP_PORT=${APP_PORT:-8501}
if [ -f /usr/local/lib/workshop-devguard.sh ]; then
    source /usr/local/lib/workshop-devguard.sh
    devguard_acquire "$APP_PORT"
fi

# Startup timing
T0=$(date +%s%3N 2>/dev/null || python3 -c "import time;print(int(time.time()*1000))")
elapsed() { echo $(( $(date +%s%3N 2>/dev/null || python3 -c "import time;print(int(time.time()*1000))") - T0 )); }

# Skip sync if lockfile unchanged (fast restart)
UV_HASH=$(md5sum uv.lock 2>/dev/null | cut -d' ' -f1)
if [ ! -f ".venv/.uv-hash-$UV_HASH" ]; then
  echo "[+$(elapsed)ms] uv sync starting..."
  uv sync --compile-bytecode --frozen
  rm -f .venv/.uv-hash-* 2>/dev/null
  touch ".venv/.uv-hash-$UV_HASH"
  echo "[+$(elapsed)ms] uv sync done"
else
  echo "[+$(elapsed)ms] uv sync skipped (lockfile unchanged)"
fi

echo "[+$(elapsed)ms] Starting Streamlit app on http://localhost:${APP_PORT}"
exec uv run streamlit run app.py --server.port=${APP_PORT} --server.headless=true
