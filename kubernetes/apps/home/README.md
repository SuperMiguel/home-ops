# Home automation

## Node-RED

| Item | Value |
|------|--------|
| URL | https://nodered.veliz.cc |
| Config repo (private) | [Super-Node-RED](https://github.com/SuperMiguel/Super-Node-RED) |
| PVC | Longhorn `5Gi` at `/data` |
| Argo app | `node-red` (namespace `home`) |

**Secrets (required):** see **[node-red/SECRETS.md](./node-red/SECRETS.md)** — `GITHUB_TOKEN` (read **and write**) + `NODE_RED_CREDENTIAL_SECRET`.

Uses Node-RED **Projects** (built-in Git): init clones into `/data/projects/super`; you **commit/push** from the editor History sidebar back to Super-Node-RED.

**Resources (2026-05):** app container requests **1 CPU / 1 Gi**, limits **2 CPU / 2 Gi**, plus `NODE_OPTIONS=--max-old-space-size=1536`. Kubernetes does not throttle CPU today unless a `limits.cpu` is set too low; the editor is often **browser-bound** or slowed by **bad HA websocket reconnects** (fix the long-lived token in flows).

**Slow editor?** Compare:

1. `kubectl -n home port-forward svc/node-red 1880:1880` → http://127.0.0.1:1880 (bypasses Envoy)
2. https://nodered.veliz.cc (full path)

If (1) is fast and (2) is slow, the bottleneck is ingress/DNS, not pod CPU. Check Node-RED logs for `Invalid access token for WebSocket` on the Home Assistant config node.

### Cutover

DNS **`nodered.veliz.cc`**. Update flows still pointing at old HA **`10.0.20.40`** → **`10.0.20.50`** or `https://hass.veliz.cc`.

---

## Mosquitto (MQTT)

| Item | Value |
|------|--------|
| Broker (LAN) | **`10.0.20.41:1883`** (Cilium LoadBalancer — same IP as former Proxmox VM) |
| In-cluster | `mosquitto.home.svc.cluster.local:1883` |
| Argo app | `mosquitto` |

**Before sync:** stop the Proxmox **mqtt** VM on `10.0.20.41` so the cluster can take the IP.

Config starts with **`allow_anonymous true`** (no auth file in Git). If the old broker used passwords, copy `passwd` from Proxmox into the PVC and switch to `password_file` in `mosquitto/values.yaml` (see comment in config).

Optional: copy persistence from PVE into Longhorn PVC `mosquitto` at `/mosquitto/data` to keep retained MQTT messages.

Node-RED broker URL is updated in [Super-Node-RED](https://github.com/SuperMiguel/Super-Node-RED) (`Super-MQTT-broker` → `10.0.20.41`). Commit/push flows, then deploy Node-RED or pull in the editor.

---

## Home Assistant

| Item | Value |
|------|--------|
| HTTPS | https://hass.veliz.cc |
| LAN | http://10.0.20.50:8123 |
| Config in Git | `home-assistant/resources/config/` (MQTT, Lovelace tablet dashboard) |
| Argo app | `home-assistant` |

**Fresh install** — no Proxmox restore. Add **Hubitat** (×2) + **Ecobee** in UI; tablet kiosk → `https://hass.veliz.cc/lovelace-tablet?kiosk`. See **[home-assistant/README.md](./home-assistant/README.md)**.

---

## Homebridge

Three Homebridge instances (downstairs / upstairs / alarm). **No config in Git** — use the UI after deploy.

| Instance | URL | Node | Old PVE IP |
|----------|-----|------|------------|
| Downstairs | https://homebridge-downstairs.veliz.cc | `hl-k8s-32` | 10.0.20.42 |
| Upstairs | https://homebridge-upstairs.veliz.cc | `hl-k8s-33` | 10.0.20.43 |
| Alarm | https://homebridge-alarm.veliz.cc | `hl-k8s-34` | 10.0.20.44 |

Each uses **hostNetwork** (required for HomeKit/mDNS) and a **Longhorn PVC** at `/homebridge`.

Config backups (with secrets): [Super-Veliz-Network `software/homebridge`](https://github.com/SuperMiguel/Super-Veliz-Network/tree/master/software/homebridge) (private repo).

## Fresh start (wipe old config)

```sh
kubectl -n home scale deployment homebridge-downstairs homebridge-upstairs homebridge-alarm --replicas=0
kubectl -n home delete pvc homebridge-downstairs homebridge-upstairs homebridge-alarm
kubectl -n home scale deployment homebridge-downstairs homebridge-upstairs homebridge-alarm --replicas=1
```

## Manual setup (UI)

1. Open the URL for each bridge.
2. Default login is often **admin** / **admin** (change on first visit).
3. Install **homebridge-hubitat-tonesto7** (or your Hubitat plugin).
4. Paste the platform block from the **Hubitat Homebridge app** config generator.
5. Restart Homebridge from the UI when prompted.

## Optional: restore from Proxmox backup

```sh
kubectl -n home cp ./homebridge-alarm-backup/. home/homebridge-alarm-0:/homebridge/
kubectl -n home rollout restart deployment homebridge-alarm
```

Same pattern for downstairs / upstairs.
