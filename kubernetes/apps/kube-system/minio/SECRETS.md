# MinIO secrets (1Password)

Homelab vault item **`minio-secrets`** (root credentials for the in-cluster MinIO on SuperUNAS `Longhorn_Backups`).

| Field (concealed) | Value |
| --- | --- |
| `MINIO_ROOT_USER` | Access key (e.g. `openssl rand -hex 12`) |
| `MINIO_ROOT_PASSWORD` | Secret key (e.g. `openssl rand -hex 32`) |

ExternalSecret remote refs:

- `minio-secrets/MINIO_ROOT_USER`
- `minio-secrets/MINIO_ROOT_PASSWORD`

The same item is templated into `longhorn-system/longhorn-backup-credentials` for Longhorn’s S3 backup target (see `../longhorn/SECRETS.md`).

**Console:** https://minio.veliz.cc (envoy-internal). API for Longhorn: `http://minio.minio.svc.cluster.local:9000`.
