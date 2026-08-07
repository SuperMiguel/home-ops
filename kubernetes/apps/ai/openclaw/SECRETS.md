# OpenClaw secrets (1Password)

Create item **`openclaw-secrets`** in the **Homelab** vault (same vault as other ExternalSecrets).

| Field (concealed) | Value |
| --- | --- |
| `OPENCLAW_GATEWAY_TOKEN` | Long random string (Control UI + Cursor MCP auth). Example: `openssl rand -hex 32` |
| `DISCORD_BOT_TOKEN` | Bot token from [Discord Developer Portal](https://discord.com/developers/applications) |
| `OLLAMA_API_KEY` | Literal `ollama-local` (marker for LAN Ollama; not a real secret) |

ExternalSecret keys must match:

- `openclaw-secrets/OPENCLAW_GATEWAY_TOKEN`
- `openclaw-secrets/DISCORD_BOT_TOKEN`
- `openclaw-secrets/OLLAMA_API_KEY`

Argo will not get a usable Secret until this item exists. See [software/openclaw README](https://github.com/SuperMiguel/Super-Veliz-Network/blob/main/software/openclaw/README.md) for Discord bot + Ollama LAN steps.
