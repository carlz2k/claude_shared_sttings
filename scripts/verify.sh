#!/bin/bash
# Check that the optimized setup is active on this machine. Exit code = number of failed checks.
FAIL=0
ok()   { echo "PASS  $1"; }
bad()  { echo "FAIL  $1"; FAIL=$((FAIL + 1)); }
PORT="${HEADROOM_PORT:-8787}"

# 1. A real rg binary must exist: Claude Code only defines an `rg` shell function, and `rtk rg` needs the binary.
RG=$(/bin/zsh -fc 'command -v rg' 2>/dev/null)
case "$RG" in /*) ok "real rg binary: $RG" ;; *) bad "no real rg binary (brew install ripgrep)" ;; esac

# 2. rtk is installed and `rtk rg` actually runs.
if command -v rtk >/dev/null 2>&1; then
  T=$(mktemp); printf 'alpha\nneedle\n' > "$T"
  if rtk rg -n needle "$T" 2>&1 | grep -q needle; then ok "rtk rg works"; else bad "rtk rg fails"; fi
  rm -f "$T"
else bad "rtk not installed"; fi

# 3. The running Headroom proxy protects Read results.
PID=$(lsof -nP -iTCP:"$PORT" -sTCP:LISTEN -t 2>/dev/null | head -1)
if [ -z "$PID" ]; then bad "no headroom proxy on port $PORT"
elif ps eww -p "$PID" | tr ' ' '\n' | grep -q '^HEADROOM_PROTECT_TOOL_RESULTS=.*Read'; then ok "proxy pid $PID protects Read"
else bad "proxy pid $PID lacks HEADROOM_PROTECT_TOOL_RESULTS=Read (run scripts/restart-headroom-proxy.sh)"; fi

# 4. Subagent default model and rules are in place.
grep -q '"CLAUDE_CODE_SUBAGENT_MODEL"' "$HOME/.claude/settings.json" 2>/dev/null && ok "CLAUDE_CODE_SUBAGENT_MODEL set" || bad "CLAUDE_CODE_SUBAGENT_MODEL not set in ~/.claude/settings.json"
grep -q 'Never omit' "$HOME/.claude/rules/tool-choice.md" 2>/dev/null && ok "tool-choice.md has the explicit-model rule" || bad "~/.claude/rules/tool-choice.md missing or outdated"
[ -f "$HOME/.claude/agents/Explore.md" ] && ok "Explore.md installed" || bad "Explore.md missing"

echo "$FAIL check(s) failed"; exit "$FAIL"
