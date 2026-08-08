# OpenClaw / AI stack secrets (1Password)

One Homelab vault item **`openclaw-secrets`** for everything in namespace `ai` (OpenClaw, Grafana MCP, …).

| Field (concealed) | Value |
| --- | --- |
| `OPENCLAW_GATEWAY_TOKEN` | Long random string (Control UI + Cursor MCP). Example: `openssl rand -hex 32` |
| `DISCORD_BOT_TOKEN` | Discord bot token |
| `OLLAMA_API_KEY` | Literal `ollama-local` (LAN Ollama marker) |
| `GRAFANA_SERVICE_ACCOUNT_TOKEN` | Grafana SA token (Viewer) for grafana-mcp |
| `HOME_ASSISTANT_TOKEN` | HA long-lived access token for OpenClaw → native `/api/mcp` |

ExternalSecret remote refs:

- `openclaw-secrets/OPENCLAW_GATEWAY_TOKEN`
- `openclaw-secrets/DISCORD_BOT_TOKEN`
- `openclaw-secrets/OLLAMA_API_KEY`
- `openclaw-secrets/GRAFANA_SERVICE_ACCOUNT_TOKEN`
- `openclaw-secrets/HOME_ASSISTANT_TOKEN`

**Grafana token:** Administration → Service accounts → Add (`openclaw-mcp`, role Viewer) → Add token → paste into the field above.

**Home Assistant token + MCP server:**

1. HA → **Settings → Devices & services → Add integration → Model Context Protocol Server**
2. Prefer **Assist** API. Optionally leave **Control Home Assistant** off until Discord tool use is trusted (OpenClaw also filters to read-only tools).
3. Expose entities under **Settings → Voice assistants → Expose** (only what SuperClaw should see).
4. **Profile → Security → Long-lived access tokens** → Create (`openclaw-mcp`) → paste into `HOME_ASSISTANT_TOKEN`.

See [software/openclaw](https://github.com/SuperMiguel/Super-Veliz-Network/blob/main/software/openclaw/README.md) and [MCP.md](https://github.com/SuperMiguel/Super-Veliz-Network/blob/main/software/openclaw/MCP.md).
