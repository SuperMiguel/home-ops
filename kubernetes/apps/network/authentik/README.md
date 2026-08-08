# Authentik (SSO)

Internal IdP at **https://auth.veliz.cc** (`envoy-internal`).

## Phase 1 — deploy

1. Create 1Password item `authentik-secrets` (see `SECRETS.md`).
2. Argo syncs chart `authentik` **2026.5.6** into namespace `authentik` (Postgres on Longhorn).
3. Open https://auth.veliz.cc — log in as **`akadmin`** with `AUTHENTIK_BOOTSTRAP_PASSWORD`.
4. Change password if you want; create your personal admin user.

## Phase 2 — domain forward-auth (Envoy)

Protects apps that lack good native SSO by checking cookies at the gateway.

| Piece | What |
| --- | --- |
| Blueprint `Envoy Forward Auth` | Proxy provider (domain level), app slug `envoy`, assigned to **authentik Embedded Outpost** |
| Service `ak-outpost-authentik-embedded-outpost:9000` | Points at authentik-server (embedded outpost) |
| HTTPRoute extra rule | `/outpost.goauthentik.io` → outpost Service |
| `ReferenceGrant` | Lets `SecurityPolicy` in `default` / `longhorn-system` / `minio` call the outpost |
| `SecurityPolicy` | Homepage, Longhorn, MinIO console → `/outpost.goauthentik.io/auth/envoy` |

Protected today:

- https://home.veliz.cc
- https://longhorn.veliz.cc
- https://minio.veliz.cc

Cookie domain is **`veliz.cc`** (shared with `auth.veliz.cc`). After login once, other protected hosts reuse the session.

**Verify in Authentik UI:** Applications → Envoy; Outposts → authentik Embedded Outpost lists the Envoy provider. Outpost config must have `authentik_host` / `authentik_host_browser` = `https://auth.veliz.cc` (otherwise redirects go to `localhost`). Brand domain should be `auth.veliz.cc`.

## Phase 2b — native OIDC (next)

| App | Notes |
| --- | --- |
| Grafana | OIDC; turn off anonymous |
| Argo CD | OIDC |

## Ops

- UI: https://auth.veliz.cc
- Namespace: `authentik`
- DB PVC: Longhorn `8Gi` (chart Postgres — fine for single-node IdP; move to CNPG later if needed)
- Do **not** rotate `AUTHENTIK_SECRET_KEY` after install
- Needs Envoy Gateway **≥ 1.7.1** so ext-auth `Location` redirects work (cluster is on 1.7.3)
