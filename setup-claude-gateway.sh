#!/usr/bin/env bash
set -euo pipefail

# ── config ────────────────────────────────────────────────────────────────────
GATEWAY_NAME="Harshpreet's gateway"
GATEWAY_URL="http://127.0.0.1:3456"
GATEWAY_API_KEY="sk-litellm"
PROFILE_ID="00000000-0000-4000-8000-000000000114"
MODELS='["kimi-latest", "glm-latest", "open-large", "open-fast", "glm-flash-experimental"]'

NORMAL_DIR="$HOME/Library/Application Support/Claude"
THIRD_PARTY_DIR="$HOME/Library/Application Support/Claude-3p"
CONFIG_LIB="$THIRD_PARTY_DIR/configLibrary"

# ── helpers ───────────────────────────────────────────────────────────────────
write_json() {
  local path="$1"
  local content="$2"
  mkdir -p "$(dirname "$path")"
  printf '%s\n' "$content" > "$path"
}

merge_deployment_mode() {
  local path="$1"
  local mode="$2"
  if [[ -f "$path" ]]; then
    python3 -c "
import json, sys
with open('$path') as f:
    cfg = json.load(f)
cfg['deploymentMode'] = '$mode'
print(json.dumps(cfg, indent=2))
" > "${path}.tmp" && mv "${path}.tmp" "$path"
  else
    mkdir -p "$(dirname "$path")"
    printf '{"deploymentMode":"%s"}\n' "$mode" > "$path"
  fi
}

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

# ── main ──────────────────────────────────────────────────────────────────────
echo "Setting up '${GATEWAY_NAME}' → ${GATEWAY_URL}"

# 1. Normal profile: just flip deploymentMode to 3p
merge_deployment_mode "$NORMAL_DIR/claude_desktop_config.json" "3p"
echo "  ✓ $NORMAL_DIR/claude_desktop_config.json"

# 2. Third-party profile dir: deploymentMode 3p
merge_deployment_mode "$THIRD_PARTY_DIR/claude_desktop_config.json" "3p"
echo "  ✓ $THIRD_PARTY_DIR/claude_desktop_config.json"

# 3. _meta.json  — record which profile is active
META_CONTENT=$(python3 -c "
import json, os
path = '${CONFIG_LIB}/_meta.json'
meta = {}
if os.path.exists(path):
    try:
        with open(path) as f:
            meta = json.load(f)
    except Exception:
        meta = {}
meta['appliedId'] = '${PROFILE_ID}'
entries = [e for e in meta.get('entries', []) if e.get('id') != '${PROFILE_ID}']
entries.append({'id': '${PROFILE_ID}', 'name': '''${GATEWAY_NAME}'''})
meta['entries'] = entries
print(json.dumps(meta, indent=2))
")
write_json "$CONFIG_LIB/_meta.json" "$META_CONTENT"
echo "  ✓ $CONFIG_LIB/_meta.json"

# 4. Gateway profile — the actual inference config
PROFILE_CONTENT=$(python3 -c "
import json
profile = {
    'inferenceProvider': 'gateway',
    'inferenceGatewayBaseUrl': '${GATEWAY_URL}',
    'inferenceGatewayApiKey': '${GATEWAY_API_KEY}',
    'inferenceGatewayAuthScheme': 'bearer',
    'inferenceModels': ${MODELS},
    'disableDeploymentModeChooser': True
}
print(json.dumps(profile, indent=2))
")
write_json "$CONFIG_LIB/${PROFILE_ID}.json" "$PROFILE_CONTENT"
echo "  ✓ $CONFIG_LIB/${PROFILE_ID}.json"

echo ""
echo "Profile: '${GATEWAY_NAME}'"
echo "Gateway: ${GATEWAY_URL}"
echo "Models:  $(echo $MODELS | tr -d '[]"' | tr ',' ' ')"
echo ""

# 5. Restart Claude Desktop
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
echo "Done. To restore normal Anthropic Claude:"
echo "  ollama launch claude-desktop --restore"
