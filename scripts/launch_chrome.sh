#!/usr/bin/env bash
# launch_chrome.sh - Launch Chrome with CDP remote debugging for Google Flow
set -euo pipefail

PORT="${CDP_PORT:-9222}"
PROFILE_DIR="${CHROME_FLOW_PROFILE:-$HOME/.config/google-chrome-flow}"
FLOW_URL="https://flow.google.com"

# Check if already listening on port
if curl -s "http://127.0.0.1:${PORT}/json/version" >/dev/null 2>&1; then
  echo "Chrome CDP is already active and listening on port ${PORT}."
  exit 0
fi

# Locate Chrome binary
CHROME_BIN=""
for candidate in \
  "/opt/google/chrome/chrome" \
  "/usr/bin/google-chrome" \
  "/usr/bin/google-chrome-stable" \
  "/usr/bin/chromium" \
  "/usr/bin/chromium-browser"; do
  if [[ -x "$candidate" ]]; then
    CHROME_BIN="$candidate"
    break
  fi
done

if [[ -z "$CHROME_BIN" ]]; then
  echo "Error: Google Chrome binary not found." >&2
  exit 1
fi

mkdir -p "$PROFILE_DIR"

echo "Launching Chrome with remote debugging on port ${PORT}..."
echo "Profile directory: ${PROFILE_DIR}"

nohup "$CHROME_BIN" \
  --remote-debugging-port="${PORT}" \
  --user-data-dir="${PROFILE_DIR}" \
  "$FLOW_URL" >/dev/null 2>&1 &

# Wait for CDP endpoint to respond
ATTEMPTS=0
MAX_ATTEMPTS=20
until curl -s "http://127.0.0.1:${PORT}/json/version" >/dev/null 2>&1; do
  ATTEMPTS=$((ATTEMPTS + 1))
  if [[ $ATTEMPTS -ge $MAX_ATTEMPTS ]]; then
    echo "Error: Timed out waiting for Chrome CDP on port ${PORT}." >&2
    exit 1
  fi
  sleep 0.5
done

echo "Chrome CDP successfully ready on http://127.0.0.1:${PORT}."
