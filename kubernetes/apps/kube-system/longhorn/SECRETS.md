# Longhorn backup secrets (1Password)

Uses Homelab vault item **`minio-secrets`** (same as MinIO). See `../minio/SECRETS.md`.

ExternalSecret `longhorn-backup-credentials` templates:

| Secret key | Source |
| --- | --- |
| `AWS_ACCESS_KEY_ID` | `minio-secrets/MINIO_ROOT_USER` |
| `AWS_SECRET_ACCESS_KEY` | `minio-secrets/MINIO_ROOT_PASSWORD` |
| `AWS_ENDPOINTS` | `http://minio.minio.svc.cluster.local:9000` (fixed) |
| `AWS_CERT` | empty (HTTP in-cluster) |
| `AWS_REGION` | `us-east-1` (fixed; MinIO ignores it) |

Backup target: `s3://longhorn@us-east-1/` → MinIO bucket `longhorn` on SuperUNAS share `Longhorn_Backups`.
