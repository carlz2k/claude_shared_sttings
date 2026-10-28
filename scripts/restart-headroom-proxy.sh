#!/bin/bash
# Restart the Headroom proxy so a changed HEADROOM_* variable (notably HEADROOM_PROTECT_TOOL_RESULTS) takes effect.
# The proxy reads these only at startup, and it is shared by every `headroom wrap claude` session:
# those sessions lose their connection for a few seconds. Run it when they are idle.
# Usage: restart-headroom-proxy.sh [--dry-run] [port]   (default port 8787)
set -u
DRY=0
if [ "${1:-}" = "--dry-run" ]; then DRY=1; shift; fi
PORT="${1:-8787}"
PROTECT="${HEADROOM_PROTECT_TOOL_RESULTS:-Read}"

OLD=$(lsof -nP -iTCP:"$PORT" -sTCP:LISTEN -t 2>/dev/null | head -1)
[ -n "$OLD" ] || { echo "ABORT: nothing listens on port $PORT"; exit 1; }
CMD=$(ps -o command= -p "$OLD")
case "$CMD" in
  *headroom*proxy*) ;;
  *) echo "ABORT: pid $OLD is not a headroom proxy: $CMD"; exit 1 ;;
esac

# Keep the old proxy's HEADROOM_* and ORT_* variables, except the wrapper-ownership marker and the protect list.
ENVS=()
while IFS= read -r kv; do ENVS+=("$kv"); done < <(
  ps eww -p "$OLD" | tr ' ' '\n' | grep -E '^(HEADROOM_|ORT_DYLIB_PATH=)' |
    grep -v -E '^HEADROOM_(WRAP_OWNED|PROTECT_TOOL_RESULTS)='
)
ENVS+=("HEADROOM_PROTECT_TOOL_RESULTS=$PROTECT")

echo "old pid:  $OLD"
echo "command:  $CMD"
echo "env keys: $(printf '%s\n' "${ENVS[@]}" | cut -d= -f1 | tr '\n' ' ')"
[ "$DRY" = 1 ] && { echo "dry run: nothing changed"; exit 0; }

LOG="$HOME/.headroom/logs/proxy-stdio-$PORT.log"
mkdir -p "$(dirname "$LOG")"
kill "$OLD"
for i in $(seq 1 40); do
  lsof -nP -iTCP:"$PORT" -sTCP:LISTEN >/dev/null 2>&1 || break
  sleep 0.25
done
lsof -nP -iTCP:"$PORT" -sTCP:LISTEN >/dev/null 2>&1 && { echo "ABORT: port $PORT still busy"; exit 1; }

# shellcheck disable=SC2086
nohup env "${ENVS[@]}" $CMD >>"$LOG" 2>&1 &
NEW=$!
disown "$NEW" 2>/dev/null || true
echo "new pid:  $NEW"

for i in $(seq 1 120); do
  if curl -fsS -m 2 "http://127.0.0.1:$PORT/readyz" >/dev/null 2>&1; then
    echo "ready after about $((i / 2))s"; exit 0
  fi
  sleep 0.5
done
echo "NOT READY after 60s; see $LOG"; exit 1
