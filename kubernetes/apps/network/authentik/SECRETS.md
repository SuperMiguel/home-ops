# Authentik secrets (1Password)

## Core — item `authentik-secrets`

| Field (concealed) | Value |
| --- | --- |
| `AUTHENTIK_SECRET_KEY` | Cookie/signing key — `openssl rand -base64 48` (do not rotate after first install) |
| `AUTHENTIK_BOOTSTRAP_PASSWORD` | Initial `akadmin` password — `openssl rand -base64 24` |
| `AUTHENTIK_BOOTSTRAP_EMAIL` | Your email (e.g. `miguel@veliz.cc`) |
| `POSTGRES_PASSWORD` | DB password — `openssl rand -base64 24` |

ExternalSecret remote refs: `authentik-secrets/<FIELD>`.

After first successful boot, bootstrap env vars are only needed once; keep the Secret so Postgres/Authentik keep matching credentials.

## OIDC apps (Phase 2b)

### Item `grafana-oidc`

| Field | Notes |
| --- | --- |
| `CLIENT_ID` | Authentik Provider **Grafana** client id |
| `CLIENT_SECRET` | Authentik Provider **Grafana** client secret |

→ ExternalSecret → Secret `grafana-oidc-secret` (`observability`).  
Redirect URI: `https://grafana.veliz.cc/login/generic_oauth`

### Item `argo-oidc`

| Field | Notes |
| --- | --- |
| `CLIENT_SECRET` | Authentik Provider **Argo CD** client secret |

`CLIENT_ID` lives in `argo-cd/values.yaml` (`oidc.config`) — not in 1Password.  
→ ExternalSecret merges `oidc.authentik.clientSecret` into `argocd-secret`.  
Redirect URI: `https://argo.veliz.cc/auth/callback`

If you recreate providers in Authentik, update these fields and force-sync the ExternalSecrets.
