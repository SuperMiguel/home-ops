# Home Assistant — minimal setup steps

Custom components (**HACS** + **Hubitat**) are installed by an **init container** on each pod start (pinned versions in `values.yaml`). No manual download step.

## Shortest path (Hubitat + Ecobee only)

| Step | Where | Action |
|------|--------|--------|
| 1 | Git | Push home-ops → Argo sync (or `helm upgrade` + apply kustomize) |
| 2 | HA | **Settings → System → Restart** (once, after first sync with init container) |
| 3 | Hubitat | On each hub: **Apps → Maker API** → enable devices → note IP, app ID, token |
| 4 | HA | **Add integration → Hubitat** (×2: Downstairs, Upstairs) |
| 5 | HA | **Add integration → Ecobee** (or **HomeKit Device** for thermostat) |
| 6 | Tablet | Fully Kiosk → `https://hass.veliz.cc/lovelace-tablet?kiosk` |
| 7 | Git | Edit `resources/config/dashboards/tablet.yaml` with your entity IDs |

**Skip HACS UI** if you only need Hubitat — the integration is already on disk.

## Optional: HACS (for future custom repos)

Only if you want the HACS store UI later:

1. **Add integration → HACS** → GitHub device login (one-time).
2. Do **not** reinstall Hubitat from HACS (already installed by init).

## Hubitat Maker API (per hub)

1. Hubitat web UI → **Apps** → **Maker API** → Create new instance.
2. Select devices to expose to Home Assistant.
3. In HA **Add integration → Hubitat**:
   - Hub IP (VLAN 10), e.g. `http://10.0.10.7`
   - App ID (number in Maker API URL)
   - Access token

Hubitat must reach HA at `http://10.0.20.50:8123` (or in-cluster) for event webhooks — ensure firewall allows **Servers → HA** and **Hubitat → HA** on the event port HA picks.

## Updates

Bump versions in `values.yaml` init container script, delete `custom_components/hacs` or `hubitat` on the PVC (or wipe subdirs), restart pod.
