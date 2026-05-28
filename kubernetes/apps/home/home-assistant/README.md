# Home Assistant (fresh / Git-managed)

| Item | Value |
|------|--------|
| URL | https://hass.veliz.cc |
| LAN | http://10.0.20.50:8123 |
| MQTT | `mosquitto.home.svc.cluster.local:1883` (in Git) |
| Config in Git | `resources/config/` → ConfigMaps (Argo Kustomize) |
| Integrations UI | Hubitat ×2, Ecobee (once each; tokens in PVC `.storage`) |

**No restore** from old Proxmox HA — add integrations again, keep dashboards/MQTT in Git.

## What lives in Git vs PVC

| In Git (`config/`) | On PVC only (`.storage`) |
|--------------------|---------------------------|
| `resources/config/` (`configuration.yaml`, `packages/`, `dashboards/`) | Hubitat maker API tokens |
| MQTT broker host | Ecobee OAuth |
| Lovelace YAML | Entity registry, areas, names |
| Themes (optional) | Mobile app pairings |

Later you can move `config/` to a private **Super-Home-Assistant** repo and add a git-sync init container (same pattern as Node-RED).

## First-time setup

1. Edit `resources/config/configuration.yaml` if home coordinates differ from defaults.
2. Push home-ops → Argo sync `home-assistant` (Helm + `resources/` ConfigMaps).
3. Open https://hass.veliz.cc — complete **onboarding** if prompted.
4. **Settings → Devices & services → Add integration:**
   - **Hubitat** — repeat for Downstairs and Upstairs (Maker API on each hub).
   - **Ecobee** — OAuth sign-in.
5. Edit `resources/config/dashboards/tablet.yaml` with your entities (or build in UI → **Raw configuration editor** → copy into Git).
6. **Fire tablet kiosk:** install **Fully Kiosk Browser**, start URL:
   ```
   https://hass.veliz.cc/lovelace-tablet?kiosk
   ```
   Enable kiosk mode in Fully settings; keep screen on / disable battery optimization.

## Node-RED

Point the HA server node at `http://10.0.20.50:8123` or `https://hass.veliz.cc` and create a new long-lived token.

## Scripts (optional)

`scripts/` — backup/analyze tools if you ever need them; not required for fresh install.
