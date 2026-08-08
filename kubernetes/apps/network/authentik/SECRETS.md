# Authentik secrets (1Password)

Homelab vault item **`authentik-secrets`**:

| Field (concealed) | Value |
| --- | --- |
| `AUTHENTIK_SECRET_KEY` | Cookie/signing key — `openssl rand -base64 48` (do not rotate after first install) |
| `AUTHENTIK_BOOTSTRAP_PASSWORD` | Initial `akadmin` password — `openssl rand -base64 24` |
| `AUTHENTIK_BOOTSTRAP_EMAIL` | Your email (e.g. `miguel@veliz.cc`) |
| `POSTGRES_PASSWORD` | DB password — `openssl rand -base64 24` |

ExternalSecret remote refs: `authentik-secrets/<FIELD>`.

After first successful boot, bootstrap env vars are only needed once; keep the Secret so Postgres/Authentik keep matching credentials.
