# Home Assistant secrets

Home coordinates are in Git (`config/configuration.yaml`). Edit there if needed.

## Integrations (not in Git)

Configure in the UI once; credentials stay in the Longhorn PVC under `.storage/`:

- **Hubitat** (×2) — Maker API app on each hub
- **Ecobee** — OAuth

## Long-lived token (Node-RED, scripts)

**Profile → Security → Long-lived access tokens** — do not commit tokens to Git.
