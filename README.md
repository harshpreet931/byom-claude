# byom-claude

Use Claude Desktop's UI with any LLM via LiteLLM or any compatible gateway.

## Requirements

- macOS
- Claude Desktop installed
- A running LiteLLM proxy (or any compatible gateway)

## Setup

Edit the config block at the top of `setup-claude-gateway.sh`:

```bash
GATEWAY_NAME="My Gateway"
GATEWAY_URL="http://127.0.0.1:3456"
GATEWAY_API_KEY="sk-litellm"
MODELS='["model-one", "model-two"]'
```

Then run:

```bash
./setup-claude-gateway.sh
```

## Reset

To restore normal Anthropic inference:

```bash
./reset-claude.sh
```

## Notes

- `GATEWAY_URL` must use `http://127.0.0.1` for local proxies (not `localhost`) or `https://` for remote ones
- Models must match the model IDs your gateway exposes
