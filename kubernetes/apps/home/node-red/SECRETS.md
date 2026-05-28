# Node-RED — secrets & Git (Projects)

Node-RED’s built-in **[Projects](https://nodered.org/docs/user-guide/projects/)** feature is how you commit and **push** flow changes back to GitHub from the editor (History sidebar). The cluster only supplies Git, the clone, and credentials — no custom sync sidecar.

The official `nodered/node-red` image already includes **`git`** and **`ssh-keygen`**.

---

## 1Password item: `node-red-secrets`

| Field | Required | Purpose |
|-------|----------|---------|
| **GITHUB_TOKEN** | Yes | `git clone` on first boot; `git push` / `git pull` from the editor (via stored credentials) |
| **NODE_RED_CREDENTIAL_SECRET** | Yes* | Decrypts `flows_cred.json` — see below if `credentialSecret` is commented out on Proxmox |

---

## 1. `GITHUB_TOKEN` — **Read and write**

Fine-grained PAT on GitHub:

1. **Repository:** only `SuperMiguel/Super-Node-RED`
2. **Permissions:** Repository → **Contents: Read and write** (not read-only — push from the UI needs write)
3. Store as concealed **`GITHUB_TOKEN`** in 1Password item **`node-red-secrets`**

Secret reference path must match: `node-red-secrets/GITHUB_TOKEN`

---

## 2. `NODE_RED_CREDENTIAL_SECRET`

Decrypts **`flows_cred.json`**. It must match whatever encrypted that file on Proxmox.

### `credentialSecret` commented out in `settings.js` (common)

Node-RED generated a key automatically and stored it in **`.config.runtime.json`**, not in `settings.js`:

```sh
# On Proxmox — use your real Node-RED data directory
jq -r '._credentialSecret' /path/to/nodered/.config.runtime.json
```

If empty, try:

```sh
jq -r '.credentialSecret // .__credentialSecret // ._credentialSecret' /path/to/nodered/.config.runtime.json
```

Put that **exact string** in 1Password as **`NODE_RED_CREDENTIAL_SECRET`**.

**Or** copy the file to the cluster PVC (then 1Password field is optional):

```sh
kubectl -n home cp ./.config.runtime.json home/<pod>:/data/.config.runtime.json
kubectl -n home exec <pod> -- chown 1000:1000 /data/.config.runtime.json
```

Our `settings.js` only sets `credentialSecret` when the env var exists, so it will not overwrite `.config.runtime.json`.

### `credentialSecret` set in `settings.js` on Proxmox

Use that same string in 1Password (or `docker exec … printenv NODE_RED_CREDENTIAL_SECRET` if you used an env var there).

### Do not invent a new random value

A new secret on Kubernetes will not decrypt the existing `flows_cred.json` until you re-enter credentials in the editor.

---

## What the cluster does

| Step | Behavior |
|------|----------|
| Boot | `NODE_RED_ENABLE_PROJECTS=true`, `settings.js` enables Projects (`workflow.mode: manual` by default) |
| Init | Clones Super-Node-RED into `/data/projects/super` (full git repo) |
| Init | Writes `/data/.git-credentials` so the editor can push without retyping the PAT |
| Runtime | You edit flows → **History** → stage → **commit** → **push** to `origin` |

Your repo’s root `package.json` already declares `flowFile` / `credentialsFile` — that matches the Projects layout.

---

## First visit after deploy

1. Open https://nodered.veliz.cc
2. If prompted, **open** (or create) project **`super`** — it should match `/data/projects/super` from the clone
3. Git **name/email** — pre-set in the chart (`GIT_USER_NAME` / `GIT_USER_EMAIL` in `values.yaml`). If the editor still asks, use the same values (any valid name + email; GitHub noreply is fine: `id+username@users.noreply.github.com`).
4. After editing flows: **History** (sidebar) → commit message → **Commit** → **Push** (remote icon)

**Workflow modes** (in `settings.js`, overridable in the UI):

- **`manual`** (default): you commit when ready, then push
- **`auto`**: Node-RED auto-commits locally on each deploy; you still **push** to GitHub from History when you want the repo updated

---

## Verify secrets

```sh
kubectl -n home get externalsecret node-red-secrets
kubectl -n home get secret node-red-secrets -o jsonpath='{.data}' | jq 'keys'
```

---

## Re-bootstrap from Git

Scale to 0, delete PVC `node-red-data`, sync Argo, scale up — init clones fresh into `/data/projects/super`.

---

## Not in 1Password

- **Editor login** (`httpAdminAuth`) — optional `settings.js` in the project or on the PVC
- **Hubitat / MQTT / HA passwords** — inside encrypted `flows_cred.json`
