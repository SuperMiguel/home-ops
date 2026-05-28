# Media namespace (Argo / app-template)

## Deployment `strategy: Recreate` (RWO PVCs)

If Argo shows **OutOfSync** on `sonarr`, `radarr`, `prowlarr`, `sabnzbd`, or `tautulli` with:

```text
spec.strategy.rollingUpdate: Forbidden: may not be specified when strategy `type` is 'Recreate'
```

the cluster still has an old **RollingUpdate** block. Switch to `Recreate` once, then sync in Argo:

```sh
for d in sonarr radarr prowlarr sabnzbd tautulli; do
  kubectl -n media patch deployment "$d" --type=strategic \
    -p '{"spec":{"strategy":{"type":"Recreate","rollingUpdate":null}}}'
done
```

Optional: remove manual restart drift (`kubectl.kubernetes.io/restartedAt` annotation) if deployments stay OutOfSync:

```sh
kubectl -n media annotate deployment sonarr radarr prowlarr sabnzbd tautulli kubectl.kubernetes.io/restartedAt-
```

Then **Sync** each app in Argo (or hard refresh the parent `apps` application).
