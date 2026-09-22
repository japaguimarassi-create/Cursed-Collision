#!/usr/bin/env bash
set -euo pipefail

UNIVERSE_ID="${1:-5290480963}"
PLACE_ID="${2:-15338267657}"
ROBLOX_HOST="https://apis.roblox.com"
MAX_ATTEMPTS="${MAX_ATTEMPTS:-5}"
DELAY_SECONDS="${DELAY_SECONDS:-3}"

log() {
  printf '[ROBLOX-CONNECT] %s\n' "$*"
}

fail() {
  printf '[ROBLOX-CONNECT] ERROR: %s\n' "$*" >&2
  exit 1
}

[[ "$UNIVERSE_ID" =~ ^[0-9]+$ ]] || fail "Invalid Universe ID: $UNIVERSE_ID"
[[ "$PLACE_ID" =~ ^[0-9]+$ ]] || fail "Invalid Place ID: $PLACE_ID"
command -v curl >/dev/null 2>&1 || fail "curl is required"

log "Target Universe: $UNIVERSE_ID"
log "Target Place: $PLACE_ID"

for attempt in $(seq 1 "$MAX_ATTEMPTS"); do
  log "HTTPS connectivity attempt $attempt/$MAX_ATTEMPTS"

  if curl --fail --silent --show-error --location --max-time 15 \
      --output /dev/null \
      "$ROBLOX_HOST"; then
    log "Roblox API host is reachable."
    break
  fi

  if [[ "$attempt" -eq "$MAX_ATTEMPTS" ]]; then
    fail "Could not reach $ROBLOX_HOST after $MAX_ATTEMPTS attempts."
  fi

  sleep "$DELAY_SECONDS"
done

log "Checking the public Roblox place metadata..."
metadata_url="https://develop.roblox.com/v1/universes/$UNIVERSE_ID/places?sortOrder=Asc&limit=100"

metadata=""
for attempt in $(seq 1 "$MAX_ATTEMPTS"); do
  if metadata="$(curl --fail --silent --show-error --location --max-time 15 "$metadata_url")"; then
    break
  fi

  if [[ "$attempt" -eq "$MAX_ATTEMPTS" ]]; then
    fail "Roblox accepted the network connection, but place metadata could not be read."
  fi

  sleep "$DELAY_SECONDS"
done

python3 - "$metadata" "$PLACE_ID" <<'PY'
import json
import sys

payload = json.loads(sys.argv[1])
place_id = int(sys.argv[2])

places = payload.get("data", [])
if not isinstance(places, list):
    raise SystemExit("Unexpected Roblox place metadata response.")

ids = {int(item["id"]) for item in places if isinstance(item, dict) and str(item.get("id", "")).isdigit()}
if place_id not in ids:
    raise SystemExit(f"Place {place_id} was not found under Universe {payload.get('universeId', 'unknown')}.")

print(f"[ROBLOX-CONNECT] Universe/Place relationship verified: {payload.get('universeId', 'unknown')} -> {place_id}")
PY

if [[ -n "${ROBLOX_API_KEY:-}" ]]; then
  log "ROBLOX_API_KEY is present in the runner."
else
  fail "ROBLOX_API_KEY is not available to this workflow."
fi

log "Connection test completed."
log "No Roblox place was published by this diagnostic."
