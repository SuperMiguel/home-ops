#!/usr/bin/env bash
# Restore Home Assistant /config from a Proxmox backup tarball into the K8s PVC.
#
# Usage:
#   ./restore-config.sh /path/to/backup.tar
#   ./restore-config.sh /path/to/extracted/config   # directory with configuration.yaml
#
# Prereqs: kubectl, tar; deployment home-assistant in namespace home.
set -euo pipefail

NAMESPACE="${NAMESPACE:-home}"
RELEASE="${RELEASE:-home-assistant}"
INPUT="${1:?Usage: $0 <backup.tar|/config/dir>}"

workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT

extract_config() {
  local src="$1"
  if [[ -d "$src" && -f "$src/configuration.yaml" ]]; then
    cp -a "$src/." "$workdir/config/"
    return
  fi
  if [[ ! -f "$src" ]]; then
    echo "Not a file or config dir: $src" >&2
    exit 1
  fi
  tar -xf "$src" -C "$workdir"
  if [[ -f "$workdir/homeassistant.tar.gz" ]]; then
    mkdir -p "$workdir/config"
    tar -xzf "$workdir/homeassistant.tar.gz" -C "$workdir/config"
  elif [[ -f "$workdir/data.tar.gz" ]]; then
    mkdir -p "$workdir/config"
    tar -xzf "$workdir/data.tar.gz" -C "$workdir/config"
  elif [[ -f "$workdir/configuration.yaml" ]]; then
    mv "$workdir"/* "$workdir/config/" 2>/dev/null || mkdir -p "$workdir/config" && mv "$workdir/configuration.yaml" "$workdir/config/" 2>/dev/null || true
  fi
  if [[ ! -f "$workdir/config/configuration.yaml" ]]; then
    echo "Could not find configuration.yaml in backup. Contents:" >&2
    find "$workdir" -maxdepth 3 -type f | head -30 >&2
    exit 1
  fi
}

patch_config() {
  local cfg="$workdir/config/configuration.yaml"
  if [[ ! -f "$cfg" ]]; then
    return
  fi
  echo "Patching MQTT / HTTP URLs in configuration.yaml (review diff before cutover)."
  # Common migrations: old broker .10.41 → .20.41, internal_url / external_url
  sed -i.bak \
    -e 's/10\.0\.10\.41/10.0.20.41/g' \
    -e 's/10\.0\.20\.40/10.0.20.50/g' \
    -e 's|http://10\.0\.10\.40:8123|http://10.0.20.50:8123|g' \
    -e 's|https://hass\.veliz\.io|https://hass.veliz.cc|g' \
    "$cfg" 2>/dev/null || sed -i '' \
    -e 's/10\.0\.10\.41/10.0.20.41/g' \
    -e 's/10\.0\.20\.40/10.0.20.50/g' \
    -e 's|http://10\.0\.10\.40:8123|http://10.0.20.50:8123|g' \
    -e 's|https://hass\.veliz\.io|https://hass.veliz.cc|g' \
    "$cfg"
  rm -f "$cfg.bak"
}

extract_config "$INPUT"
patch_config

deploy="$(kubectl -n "$NAMESPACE" get deploy -l "app.kubernetes.io/instance=${RELEASE}" -o jsonpath='{.items[0].metadata.name}')"
echo "Scaling down ${deploy}..."
kubectl -n "$NAMESPACE" scale "deployment/${deploy}" --replicas=0
kubectl -n "$NAMESPACE" wait --for=delete "pod" -l "app.kubernetes.io/instance=${RELEASE}" --timeout=120s 2>/dev/null || true

pod="$(kubectl -n "$NAMESPACE" run ha-restore --restart=Never \
  --image=alpine:3.21 \
  --overrides="$(cat <<EOF
{
  "spec": {
    "containers": [{
      "name": "hold",
      "image": "alpine:3.21",
      "command": ["sleep", "3600"],
      "volumeMounts": [{
        "name": "config",
        "mountPath": "/config"
      }]
    }],
    "volumes": [{
      "name": "config",
      "persistentVolumeClaim": {
        "claimName": "${RELEASE}-config"
      }
    }]
  }
}
EOF
)" -o jsonpath='{.metadata.name}')"
kubectl -n "$NAMESPACE" wait --for=condition=Ready "pod/${pod}" --timeout=120s

echo "Copying config into PVC..."
kubectl -n "$NAMESPACE" exec "$pod" -- rm -rf /config/lost+found 2>/dev/null || true
kubectl -n "$NAMESPACE" cp "$workdir/config/." "${NAMESPACE}/${pod}:/config/"
kubectl -n "$NAMESPACE" exec "$pod" -- chown -R 1000:1000 /config

kubectl -n "$NAMESPACE" delete pod "$pod" --wait=false
echo "Scaling up ${deploy}..."
kubectl -n "$NAMESPACE" scale "deployment/${deploy}" --replicas=1
echo "Done. Check: kubectl -n ${NAMESPACE} logs -f deploy/${deploy}"
echo "UI: https://hass.veliz.cc or http://10.0.20.50:8123"
