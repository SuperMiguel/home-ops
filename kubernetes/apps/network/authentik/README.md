# Authentik (SSO)

Internal IdP at **https://auth.veliz.cc** (`envoy-internal`).

## Phase 1 — deploy (this PR)

1. Create 1Password item `authentik-secrets` (see `SECRETS.md`).
2. Argo syncs chart `authentik` **2026.5.6** into namespace `authentik` (Postgres on Longhorn).
3. Open https://auth.veliz.cc — log in as **`akadmin`** with `AUTHENTIK_BOOTSTRAP_PASSWORD`.
4. Change password if you want; create your personal admin user.

## Phase 2 — protect apps (next)

Pick one path (can combine later):

| Approach | Best for | Notes |
| --- | --- | --- |
| **Envoy `SecurityPolicy` + Authentik Proxy outpost** | Homepage, Longhorn, MinIO console, etc. | Forward-auth at the gateway |
| **Native OIDC** | Grafana, Argo CD | App-level SSO; keeps API tokens working |

Suggested first cut after bootstrap:

1. Create an Authentik **Proxy Provider** + Outpost for `*.veliz.cc` (or start with Longhorn + Homepage).
2. Add Envoy Gateway `SecurityPolicy` `extAuth` → outpost Service.
3. Wire Grafana OIDC (skip anonymous) and Argo CD OIDC.

## Ops

- UI: https://auth.veliz.cc
- Namespace: `authentik`
- DB PVC: Longhorn `8Gi` (chart Postgres — fine for single-node IdP; move to CNPG later if needed)
- Do **not** rotate `AUTHENTIK_SECRET_KEY` after install
