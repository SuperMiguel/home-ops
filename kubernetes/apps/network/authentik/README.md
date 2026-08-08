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
| `ReferenceGrant` | Lets `SecurityPolicy` from app namespaces call the outpost |
| `SecurityPolicy` | Homepage, Longhorn, MinIO, media, observability, home UIs |

Protected today (forward-auth):

- https://home.veliz.cc
- https://longhorn.veliz.cc
- https://minio.veliz.cc
- Media: Seerr, Sonarr, Radarr, Prowlarr, Bazarr, SABnzbd, Tautulli
- Observability: Gatus, Prometheus, Alertmanager, Victoria Logs
- Home: Node-RED, Homebridge (alarm / downstairs / upstairs)

Intentionally **not** behind forward-auth (yet):

- Home Assistant (`hass.veliz.cc`) — Companion / LAN APIs
- OpenClaw (`openclaw.veliz.cc`) — Cursor MCP uses `wss://` + gateway token
- Mosquitto — MQTT, not HTTP

Cookie domain is **`veliz.cc`** (shared with `auth.veliz.cc`). After login once, other protected hosts reuse the session.

In-cluster Service URLs (Gatus probes, *arr sync) bypass the gateway and are unaffected.

**Verify in Authentik UI:** Applications → Envoy; Outposts → authentik Embedded Outpost lists the Envoy provider. Outpost config must have `authentik_host` / `authentik_host_browser` = `https://auth.veliz.cc` (otherwise redirects go to `localhost`). Brand domain should be `auth.veliz.cc`.

## Phase 2b — native OIDC (Grafana + Argo CD)

| App | Hostname | Authentik app slug | Notes |
| --- | --- | --- | --- |
| Grafana | https://grafana.veliz.cc | `grafana` | `auth.generic_oauth`; anonymous **off**; local admin form kept |
| Argo CD | https://argo.veliz.cc | `argo` | Native `oidc.config` (not Dex); `authentik Admins` → `role:admin` |

1Password: items `grafana-oidc` and `argo-oidc` (see `SECRETS.md`).

Issuers:

- `https://auth.veliz.cc/application/o/grafana/`
- `https://auth.veliz.cc/application/o/argo/`

Authentik **2026.5+** requires OAuth2 providers to set **Grant types** to at least `authorization_code` (and usually `refresh_token`). Empty `grant_types` yields `invalid_request` / Grafana “Login provider denied login request”.

## Ops

- UI: https://auth.veliz.cc
- Namespace: `authentik`
- DB PVC: Longhorn `8Gi` (chart Postgres — fine for single-node IdP; move to CNPG later if needed)
- Do **not** rotate `AUTHENTIK_SECRET_KEY` after install
- Needs Envoy Gateway **≥ 1.7.1** so ext-auth `Location` redirects work (cluster is on 1.7.3)
