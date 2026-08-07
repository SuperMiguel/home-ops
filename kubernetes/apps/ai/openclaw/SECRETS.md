# OpenClaw / AI stack secrets (1Password)

One Homelab vault item **`openclaw-secrets`** for everything in namespace `ai` (OpenClaw, Grafana MCP, …).

| Field (concealed) | Value |
| --- | --- |
| `OPENCLAW_GATEWAY_TOKEN` | Long random string (Control UI + Cursor MCP). Example: `openssl rand -hex 32` |
| `DISCORD_BOT_TOKEN` | Discord bot token |
| `OLLAMA_API_KEY` | Literal `ollama-local` (LAN Ollama marker) |
| `GRAFANA_SERVICE_ACCOUNT_TOKEN` | Grafana SA token (Viewer) for grafana-mcp |

ExternalSecret remote refs:

- `openclaw-secrets/OPENCLAW_GATEWAY_TOKEN`
- `openclaw-secrets/DISCORD_BOT_TOKEN`
- `openclaw-secrets/OLLAMA_API_KEY`
- `openclaw-secrets/GRAFANA_SERVICE_ACCOUNT_TOKEN`

**Grafana token:** Administration → Service accounts → Add (`openclaw-mcp`, role Viewer) → Add token → paste into the field above.

See [software/openclaw](https://github.com/SuperMiguel/Super-Veliz-Network/blob/main/software/openclaw/README.md) and [MCP.md](https://github.com/SuperMiguel/Super-Veliz-Network/blob/main/software/openclaw/MCP.md).
