# Docs site (MkDocs Material) — private GHCR image from Super-Veliz-Network
#
# 1Password item **`ghcr-pull`** (Homelab vault):
#
# | Field | Value |
# | --- | --- |
# | `username` | GitHub username (`SuperMiguel`) |
# | `password` | PAT with **`read:packages`** (classic) or fine-grained **Packages: Read** on `Super-Veliz-Network` |
#
# ExternalSecret → Secret `ghcr-pull` (`kubernetes.io/dockerconfigjson`) for image pulls.
#
# Image: `ghcr.io/supermiguel/super-veliz-network:latest` (built by Actions on docs push).
# After a docs update, either wait for Renovate/tag bump or:
#   kubectl -n default rollout restart deploy/docs
#
# URL: https://docs.veliz.cc (Authentik forward-auth)
