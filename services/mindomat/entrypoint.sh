#!/bin/sh
# Mind-o-Mat Entrypoint: startet QMD + Webapp

set -e

echo "=== Mind-o-Mat starting ==="

# 1. QMD im Hintergrund starten
echo "[1/2] Starting QMD on port 8181..."
qmd mcp --http --daemon --host 0.0.0.0 --port 8181 &
QMD_PID=$!
sleep 2

# 2. Webapp starten
echo "[2/2] Starting Webapp on port 5173..."
cd /app/webapp
exec node server.mjs
