# Discord alerts (Alertmanager + Gatus)

Same alerts that go to Pushover also post to Discord via a channel webhook.

## 1Password

Create Homelab item **`homelab-discord-alerts`** with field:

| Field | Value |
|--------|--------|
| `WEBHOOK_URL` | Discord webhook URL (`https://discord.com/api/webhooks/...`) |

Create the webhook: Discord channel → Edit channel → Integrations → Webhooks → New Webhook  
(Recommended: a dedicated `#alerts` or `#homelab-alerts` channel.)

Alertmanager and Gatus both read `homelab-discord-alerts/WEBHOOK_URL`.

## After adding the secret

Argo syncs ExternalSecrets → `alertmanager-secret` / `gatus-secret`.  
If needed: force refresh the ExternalSecrets or wait up to `refreshInterval` (24h), then confirm keys exist:

```bash
kubectl -n observability get secret alertmanager-secret -o jsonpath='{.data.DISCORD_WEBHOOK_URL}' | wc -c
kubectl -n observability get secret gatus-secret -o jsonpath='{.data.DISCORD_WEBHOOK_URL}' | wc -c
```

## Covered

- **Alertmanager** (Prometheus rules / OOM / etc.) → Pushover + Discord  
- **Gatus** (endpoint / ICMP / MQTT TCP) → Pushover + Discord  

Not covered: media Sonarr/Radarr/Seerr Apprise notifications (still Pushover-only unless you want those too).
