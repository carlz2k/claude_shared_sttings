# Source from ~/.zshrc. Routes `claude` through the Headroom proxy when it is installed.
claude() {
  if command -v headroom >/dev/null 2>&1; then
    headroom wrap claude "$@"
  else
    command claude "$@"
  fi
}
export HEADROOM_MODE=token
# Never lossy-compress Read results. Read only at proxy startup: after changing it, restart the proxy
# (scripts/restart-headroom-proxy.sh), or the running proxy keeps the old value.
export HEADROOM_PROTECT_TOOL_RESULTS=Read
