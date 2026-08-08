# Longhorn backups (SuperUNAS via MinIO)

## Why MinIO

UniFi Drive NFS works with **NFSv3** only. Longhorn’s NFS backup target requires **NFSv4**, so backups go to in-cluster MinIO over S3 while MinIO stores objects on the `Longhorn_Backups` NFS share.

## Layout

| Piece | Where |
| --- | --- |
| NFS share | SuperUNAS `Longhorn_Backups` → `/volume/.../Longhorn_Backups/.data` |
| MinIO | namespace `minio`, console https://minio.veliz.cc |
| Bucket | `longhorn` |
| Longhorn target | `s3://longhorn@us-east-1/` (endpoint via credential Secret) |
| Schedule | Daily backup 07:00 UTC, retain 7; weekly snapshot-cleanup |

## Setup

1. Create 1Password item `minio-secrets` (see `../minio/SECRETS.md`).
2. Merge/push these manifests; Argo syncs `minio` then `longhorn`.
3. Confirm:
   - `kubectl -n minio get pods` Ready
   - `kubectl -n longhorn-system get backuptarget default` → `available: true`
   - Longhorn UI → Backup → volumes listed after the first job (or trigger **Create Backup** once)

## Restore (volume)

1. Longhorn UI → **Backup** → pick volume / backup.
2. **Restore** → new volume name + size ≥ original.
3. Create a PVC that uses the restored Longhorn volume (or attach and mount), then point the app Deployment/StatefulSet at that PVC.
4. For a full app recover: scale down workload → restore volume → update PVC claim → scale up. Prefer restoring into a **new** PVC and cutting over after validation.

Disaster (cluster rebuild): install Longhorn → set the same MinIO endpoint + credentials → Backup target syncs existing backups from UNAS → restore volumes → redeploy apps from GitOps.
