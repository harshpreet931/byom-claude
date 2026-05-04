#!/usr/bin/env bash
set -euo pipefail

NORMAL_CONFIG="$HOME/Library/Application Support/Claude/claude_desktop_config.json"
THIRD_PARTY_CONFIG="$HOME/Library/Application Support/Claude-3p/claude_desktop_config.json"
META_JSON="$HOME/Library/Application Support/Claude-3p/configLibrary/_meta.json"

is_running() {
  pgrep -qf "Claude.app/Contents/MacOS/Claude" 2>/dev/null
}

quit_claude() {
  osascript -e 'tell application "Claude" to quit' 2>/dev/null || true
  local deadline=$((SECONDS + 15))
  while is_running && [[ $SECONDS -lt $deadline ]]; do sleep 0.5; done
  if is_running; then
    echo "  Claude Desktop did not quit in time — restart it manually." >&2
    return 1
  fi
}

echo "Resetting Claude Desktop to normal Anthropic mode..."

# Remove deploymentMode from normal config, preserve everything else
if [[ -f "$NORMAL_CONFIG" ]]; then
  python3 -c "
import json
with open('$NORMAL_CONFIG') as f:
    cfg = json.load(f)
cfg.pop('deploymentMode', None)
print(json.dumps(cfg, indent=2))
" > "${NORMAL_CONFIG}.tmp" && mv "${NORMAL_CONFIG}.tmp" "$NORMAL_CONFIG"
  echo "  ✓ Removed deploymentMode from $NORMAL_CONFIG"
else
  echo "  ! $NORMAL_CONFIG not found — nothing to reset"
fi

# Remove deploymentMode from Claude-3p config
if [[ -f "$THIRD_PARTY_CONFIG" ]]; then
  python3 -c "
import json
with open('$THIRD_PARTY_CONFIG') as f:
    cfg = json.load(f)
cfg.pop('deploymentMode', None)
print(json.dumps(cfg, indent=2))
" > "${THIRD_PARTY_CONFIG}.tmp" && mv "${THIRD_PARTY_CONFIG}.tmp" "$THIRD_PARTY_CONFIG"
  echo "  ✓ Removed deploymentMode from $THIRD_PARTY_CONFIG"
fi

# Clear appliedId from _meta.json so no gateway profile is active
if [[ -f "$META_JSON" ]]; then
  python3 -c "
import json
with open('$META_JSON') as f:
    meta = json.load(f)
meta.pop('appliedId', None)
print(json.dumps(meta, indent=2))
" > "${META_JSON}.tmp" && mv "${META_JSON}.tmp" "$META_JSON"
  echo "  ✓ Cleared appliedId from $META_JSON"
fi

echo ""

# Restart Claude Desktop
if is_running; then
  read -r -p "Claude Desktop is running. Restart now? [Y/n] " ans
  ans="${ans:-Y}"
  if [[ "$ans" =~ ^[Yy]$ ]]; then
    echo "  Quitting Claude Desktop..."
    quit_claude
    echo "  Opening Claude Desktop..."
    open -a Claude
    echo "  ✓ Restarted"
  else
    echo "  Restart Claude Desktop manually for changes to take effect."
  fi
else
  echo "  Opening Claude Desktop..."
  open -a Claude
  echo "  ✓ Opened"
fi

echo ""
echo "Done. Claude Desktop is now using normal Anthropic inference."
echo "To re-enable the gateway, run: ./setup-claude-gateway.sh"
