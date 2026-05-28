# Home automation (Homebridge)

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
