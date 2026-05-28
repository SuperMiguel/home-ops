# Home automation (Homebridge)

Two Homebridge instances (downstairs / upstairs). **No config in Git** — use the UI after deploy.

| Instance | URL | Node |
|----------|-----|------|
| Downstairs | https://homebridge-downstairs.veliz.cc | `hl-k8s-32` |
| Upstairs | https://homebridge-upstairs.veliz.cc | `hl-k8s-33` |

Each uses **hostNetwork** (required for HomeKit/mDNS) and a **Longhorn PVC** at `/homebridge`.

## Fresh start (wipe old config)

If a PVC already has a broken or half-migrated config:

```sh
kubectl -n home scale deployment homebridge-downstairs homebridge-upstairs --replicas=0
kubectl -n home delete pvc homebridge-downstairs homebridge-upstairs
# Sync Argo (or wait for self-heal) to recreate PVCs + pods
kubectl -n home scale deployment homebridge-downstairs homebridge-upstairs --replicas=1
```

Or delete only the PVC you want to reset (deployment name matches release name).

## Manual setup (UI)

1. Open the URL for each bridge.
2. Default login is often **admin** / **admin** (change on first visit).
3. Install **homebridge-hubitat-tonesto7** (or your Hubitat plugin).
4. Paste the platform block from the **Hubitat Homebridge app** config generator.
5. Restart Homebridge from the UI when prompted.

**Hubitat hubs (reference):**

| Bridge | Hubitat IP |
|--------|------------|
| Downstairs | `http://10.0.10.7/apps/api/` |
| Upstairs | `http://10.0.10.17/apps/api/` |

## Optional: restore from Proxmox backup

Instead of a fresh UI setup, copy the old VM’s `/homebridge` tree into the pod:

```sh
kubectl -n home cp ./homebridge-backup/. home/homebridge-downstairs-0:/homebridge/
kubectl -n home rollout restart deployment homebridge-downstairs
```

Use the same pattern for upstairs.
