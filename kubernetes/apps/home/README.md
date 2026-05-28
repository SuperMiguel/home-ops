# Home automation (Homebridge)

Two Homebridge instances (downstairs / upstairs), each on a **dedicated Talos worker** with **hostNetwork** so mDNS/HomeKit works like Docker `network_mode: host`.

## Before first sync

1. Export `/homebridge` from each Proxmox VM (or your backup tarball).
2. After Argo creates the PVC, copy data into the pod (replace release/pod names):

   ```sh
   kubectl -n home cp ./homebridge-downstairs/. \
     home/homebridge-downstairs-0:/homebridge/
   kubectl -n home cp ./homebridge-upstairs/. \
     home/homebridge-upstairs-0:/homebridge/
   kubectl -n home exec -n home deploy/homebridge-downstairs -- chown -R 1000:1000 /homebridge
   kubectl -n home exec -n home deploy/homebridge-upstairs -- chown -R 1000:1000 /homebridge
   ```

3. Confirm UI: `https://homebridge-downstairs.veliz.cc` and `https://homebridge-upstairs.veliz.cc` (internal Envoy gateway).

## Node pins

| Instance   | `nodeSelector` hostname | Old VLAN 20 IP |
|------------|-------------------------|----------------|
| downstairs | `hl-k8s-32`             | 10.0.20.42     |
| upstairs   | `hl-k8s-33`             | 10.0.20.43     |

Adjust hostnames in `values.yaml` if your Talos node names differ.

## 1Password — `homelab-homebridge`

Create one item with two concealed fields (names must match exactly):

| Field | Used by |
|-------|---------|
| `HUBITAT_UPSTAIRS_ACCESS_TOKEN` | `homebridge-upstairs` init |
| `HUBITAT_DOWNSTAIRS_ACCESS_TOKEN` | `homebridge-downstairs` init |

Synced to Kubernetes Secret `homebridge-secrets` in namespace `home` (`cluster-secrets/externalsecret-homebridge.yaml`).

## Git-managed `config.json` (both bridges)

| Instance | Config path | Hubitat hub (VLAN 10) | 1Password field |
|----------|-------------|-------------------------|-----------------|
| Upstairs | `homebridge-upstairs/resources/config.json` | `10.0.10.17` (app 162) | `HUBITAT_UPSTAIRS_ACCESS_TOKEN` |
| Downstairs | `homebridge-downstairs/resources/config.json` | `10.0.10.7` (app 194) | `HUBITAT_DOWNSTAIRS_ACCESS_TOKEN` |

Init containers seed the PVC and inject the token on every pod start. **Plugins:** copy `node_modules` and `.persist/` from each old VM, or reinstall **homebridge-hubitat-v2** via the UI.
