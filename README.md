# byom-claude

Use Claude Desktop's UI with any LLM via a compatible gateway (LiteLLM, grid.ai, etc.).

## How it works

Claude Desktop validates gateway model names client-side: they must contain `claude`, `sonnet`, `opus`, `haiku`, or `anthropic`, and must **not** contain any known non-Anthropic model name (`kimi`, `glm`, `minimax`, `gpt`, `gemini`, `qwen`, `deepseek`, `grok`, `llama`, `moonshot`, ...).

This script works around that by running a small local proxy (`~/.config/claude-gateway/proxy.js`) that:

1. Exposes safe alias names (e.g. `claude-sonnet-km`) that pass Claude Desktop's validator
2. Rewrites those aliases to real model names (e.g. `kimi-latest`) on the way out to your upstream gateway
3. Rewrites the model name back in responses so Claude Desktop stays consistent

The proxy is registered as a launchd service and starts automatically on login.

## Requirements

- macOS
- Claude Desktop installed
- Node.js (`node` on your PATH)
- An API key for your upstream gateway (e.g. grid.ai)

## Setup

```bash
./setup-claude-gateway.sh
```

The script will:
- Prompt for your upstream API key (saved to `~/.config/claude-gateway/.env`, not re-asked on future runs)
- Write and start the local proxy on `http://127.0.0.1:3456`
- Register it as a launchd service (auto-starts on login)
- Configure Claude Desktop to use it
- Restart Claude Desktop

## Model aliases

The default alias map (edit `ALIAS_KEYS` / `ALIAS_VALS` at the top of `setup-claude-gateway.sh` to change):

| Alias (Claude Desktop sees) | Real upstream model |
|---|---|
| `claude-sonnet-km` | `kimi-latest` |
| `claude-sonnet-gl` | `glm-latest` |
| `claude-haiku-gl-flash` | `glm-flash-experimental` |
| `claude-opus-mm` | `minimaxai/minimax-m2` |
| `claude-opus-ol` | `open-large` |
| `claude-haiku-of` | `open-fast` |

To add or change models, edit the two parallel arrays and re-run the script.

## Reset

To stop the proxy and restore normal Anthropic inference:

```bash
./reset-claude.sh
```

This stops and unregisters the launchd proxy, removes the `deploymentMode` override from Claude Desktop's config, and restarts the app.

## Proxy logs

```bash
tail -f ~/.config/claude-gateway/proxy.log
```

## Manual proxy control

```bash
# Stop
launchctl unload ~/Library/LaunchAgents/net.juspay.claude-gateway.plist

# Start
launchctl load ~/Library/LaunchAgents/net.juspay.claude-gateway.plist
```
