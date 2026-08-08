# Docs site (MkDocs Material) — private GHCR image from Super-Veliz-Network
#
# 1Password item title must be exactly **`ghcr-pull`** in the **Homelab** vault
# (same vault as `homepage-secrets` / `openclaw-secrets`). Use a Login or API
# Credential item with these field labels (case-sensitive):
#
# | Field | Value |
# | --- | --- |
# | `USERNAME` | GitHub username (`SuperMiguel`) |
# | `PASSWORD` | PAT with **`read:packages`** (classic) or fine-grained **Packages: Read** on `Super-Veliz-Network` |
#
# ExternalSecret → Secret `ghcr-pull` (`kubernetes.io/dockerconfigjson`) for image pulls.
#
# Image: `ghcr.io/supermiguel/super-veliz-network:sha-<git>` (built by Actions on docs push).
# Bump the tag in `values.yaml` after a docs change (Spegel can cache `:latest`).
#
# URL: https://docs.veliz.cc (Authentik forward-auth)
