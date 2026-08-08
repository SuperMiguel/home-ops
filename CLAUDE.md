# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A GitOps home Kubernetes cluster (Talos Linux + Argo CD), forked from `ajaykumar4/cluster-template`
(`upstream` remote). Argo CD watches this repo directly — merging to `main` deploys. There is no
separate build/test/deploy pipeline to invoke; changes take effect by being pushed.

## Secrets — read before touching anything

The repo root contains **live, unencrypted credentials**, not samples: `age.key` (sops decryption
key), `kubeconfig`, `github-deploy.key(.pub)`, `github-push-token.txt`, `cloudflare-tunnel.json`.
Never read, print, log, or commit the contents of these files or of any `*.sops.yaml` /
`*.sops.*` file's decrypted form. In-cluster secrets are sops-encrypted with age
(`.sops.yaml` defines the rules) — encrypted files are safe to view/commit as-is; only decrypted
output is sensitive. `SOPS_AGE_KEY_FILE`, `KUBECONFIG`, and `TALOSCONFIG` are already exported via
`.mise.toml` / `Taskfile.yaml`, so tasks run without extra setup once `mise install` has been run.

## Commands

Tooling is pinned via `mise` (`.mise.toml`) — run `mise install` once, then use `task` (go-task) for
everything; do not call `kubectl`/`helm`/`sops`/`talhelper` etc. directly unless a task doesn't exist
for what you need.

- `task` — list all tasks (root `Taskfile.yaml` includes `.taskfiles/{bootstrap,talos,template}`).
- `task reconcile` — force Argo CD to sync all apps (`ARGOCD_USE_CORE=1 task reconcile` after
  `task argocd-login-core`, to avoid port-forwarding).
- `task template:debug` — dump common cluster resources (certificates, kustomizations, pods, ...)
  across all namespaces; useful first step when diagnosing a broken app.
- `task template:configure` — re-render templated config from `cluster.yaml`/`nodes.yaml` via
  makejinja, then validate (cue schemas, kubeconform, talhelper) and sops-encrypt any new
  `*.sops.*` files. Run after editing `cluster.yaml`/`nodes.yaml` or the `templates/` sources.
- `task talos:apply-node IP=...` / `task talos:upgrade-node IP=...` / `task talos:upgrade-k8s` —
  per-node Talos/Kubernetes changes.
- `task bootstrap:talos` / `task bootstrap:apps` — initial cluster bring-up (destructive on a live
  cluster; only relevant when re-bootstrapping).

There are no application unit tests in this repo. `.github/workflows/e2e.yaml` is upstream-template
CI (`if: github.repository == 'ajaykumar4/cluster-template'`) that exercises `task init` →
`task configure` → `task bootstrap:*` end-to-end on throwaway config; it does not run against this
fork's real cluster and isn't something to run locally for a normal change.

## Architecture

**Two-layer Argo CD structure**, both required for an app to actually run:

- `kubernetes/argo/apps/<namespace>/<app>.yaml` — the Argo CD `Application` object: which Helm chart
  (if any) + which path in this repo to source values/manifests from, sync policy, target namespace.
- `kubernetes/apps/<namespace>/<app>/` — the app's own content: `values.yaml` (Helm values, often
  paired with a `values.sops.yaml` for secrets), `resources/` (extra manifests via `kustomization.yaml`,
  e.g. Homepage's `services.yaml`/`widgets.yaml` or an app's raw `configuration.yaml`), and sometimes
  `SETUP.md` / `SECRETS.md` / `scripts/` for one-off ops (e.g. Home Assistant's backup/restore scripts).

Namespaces under `kubernetes/apps/` mirror the `kubernetes/argo/apps/` tree: `default`, `network`,
`home`, `observability`, `cert-manager`, `argo-system`, `kube-system`, `ai`, `media`,
`system-upgrade`. To add a new app, create matching directories in both trees following an existing
sibling (e.g. `kubernetes/apps/network/echo` + `kubernetes/argo/apps/network/echo.yaml`) — Argo CD
picks it up automatically once merged to `main` (root `Application` in `kubernetes/argo/settings`
watches the `argo/apps` tree, sync is `automated` with `prune: true, selfHeal: true`).

**Config generation**: `cluster.yaml` and `nodes.yaml` (real cluster config, not the `.sample.yaml`
originals) plus `templates/` (Jinja2 sources) are rendered by `makejinja` (`makejinja.toml`) into the
actual `bootstrap/`, `kubernetes/`, and `talos/` trees via `task template:configure`. Prefer editing
`cluster.yaml`/`nodes.yaml`/`templates/` and re-rendering over hand-editing generated output when a
change is cluster-wide (domain, node list, common patches); edit files under `kubernetes/apps/**`
directly for per-app changes.

**Talos**: node/cluster config lives in `talos/` (`talconfig.yaml`, generated `clusterconfig/`),
driven by `talhelper` and applied via `talosctl`. `talos/talsecret.sops.yaml` is the sops-encrypted
Talos secrets bundle.

Related repos, deployed *through* this one (edit them in their own repo, not here):
[`Super-Node-RED`](https://github.com/SuperMiguel/Super-Node-RED) (`kubernetes/apps/home/node-red`),
[`Super-Veliz-Network`](https://github.com/SuperMiguel/Super-Veliz-Network) docs site
(`kubernetes/apps/default/docs`).
