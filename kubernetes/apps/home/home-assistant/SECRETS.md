# Home Assistant secrets

Home coordinates are in Git (`config/configuration.yaml`). Edit there if needed.

## Integrations (not in Git)

Configure in the UI once; credentials stay in the Longhorn PVC under `.storage/`:

- **Hubitat** (×2) — Maker API app on each hub
- **Ecobee** — OAuth

## Long-lived token (Node-RED, scripts, OpenClaw)

**Profile → Security → Long-lived access tokens** — do not commit tokens to Git.

| Consumer | 1Password |
| --- | --- |
| Node-RED | Stored in Node-RED credential secret / flows (not Git) |
| OpenClaw MCP | Homelab item **`openclaw-secrets`** field `HOME_ASSISTANT_TOKEN` |

Also enable **Model Context Protocol Server** (Assist API) so OpenClaw can call `http://home-assistant-app.home.svc:8123/api/mcp`. Details: `kubernetes/apps/ai/openclaw/SECRETS.md`.
