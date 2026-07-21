# Media namespace (Argo / app-template)

## Kometa (kids content ratings)

CronJob `kometa` remaps mature Plex ratings (`NC-17`, `X`, `AO`, `Adults Only`) → `R` so Plex share restrictions that block **R** also hide those titles.

1. Add to 1Password `homelab-media-api-keys`: `PLEX_URL`, `PLEX_TOKEN`, `TMDB_API_KEY`
2. Confirm the library key in `kometa/values.yaml` matches Plex (default: `Movies`)
3. After ExternalSecret syncs: `kubectl create job -n media kometa-now --from=cronjob/kometa`

## Deployment `strategy: Recreate` (RWO PVCs)

If Argo shows **OutOfSync** on `sonarr`, `radarr`, `prowlarr`, `sabnzbd`, `seerr`, `bazarr`, or `tautulli` with:

```text
spec.strategy.rollingUpdate: Forbidden: may not be specified when strategy `type` is 'Recreate'
```

the cluster still has an old **RollingUpdate** block. Switch to `Recreate` once, then sync in Argo:

```sh
for d in sonarr radarr prowlarr sabnzbd seerr bazarr tautulli; do
  kubectl -n media patch deployment "$d" --type=strategic \
    -p '{"spec":{"strategy":{"type":"Recreate","rollingUpdate":null}}}'
done
```

Optional: remove manual restart drift (`kubectl.kubernetes.io/restartedAt` annotation) if deployments stay OutOfSync:

```sh
kubectl -n media annotate deployment sonarr radarr prowlarr sabnzbd seerr bazarr tautulli kubectl.kubernetes.io/restartedAt-
```

Then **Sync** each app in Argo (or hard refresh the parent `apps` application).
