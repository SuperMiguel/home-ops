# Homepage secrets (1Password)

Homelab vault item **`homepage-secrets`**. Synced by ExternalSecret → K8s secret `homepage-secrets` in namespace `default`.

| Field (concealed) | 1Password item / key | Used for |
| --- | --- | --- |
| `PROXMOX_API_PASSWORD` | `homepage-secrets` | Widget token for `api-homepage@pam!homepage` on HL-PVE-35/36 |
| `UNIFI_USERNAME` | `homelab-unifi-poller` / `UNIFI_POLLER_USER` | Same read-only UniFi user as Unpoller |
| `UNIFI_PASSWORD` | `homelab-unifi-poller` / `UNIFI_POLLER_PASSWORD` | UniFi password (shared with Unpoller) |
| `HOMEBRIDGE_PASSWORD` | `homepage-secrets` | Shared Homebridge UI password (if widget used) |
| `OPENMETEO_LATITUDE` | `homepage-secrets` | Weather widget |
| `OPENMETEO_LONGITUDE` | `homepage-secrets` | Weather widget |
| `SONARR_API_KEY` | `homelab-media-api-keys` | Sonarr widget (shared with media ns) |
| `RADARR_API_KEY` | `homelab-media-api-keys` | Radarr widget |
| `PROWLARR_API_KEY` | `homelab-media-api-keys` | Prowlarr widget |
| `SABNZBD_API_KEY` | `homelab-media-api-keys` | SABnzbd widget |
| `TAUTULLI_API_KEY` | `homelab-media-api-keys` | Tautulli widget |
| `BAZARR_API_KEY` | `homelab-media-api-keys` | Bazarr widget |
| `SEERR_API_KEY` | `homelab-media-api-keys` | Seerr widget |

Live config: `resources/config/*.yaml` (not the archived standalone Homepage git repo).

If values may have leaked from old `SuperMiguel/homepage` git history, rotate via [docs: leaked homepage credentials](https://docs.veliz.cc/software/secrets-rotation-homepage/) then update the 1Password items above (and media apps that share `homelab-media-api-keys`).
