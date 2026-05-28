#!/usr/bin/env bash
# Download Home Assistant backup from a running instance.
#
#   export HA_URL=http://10.0.20.40:8123
#   export HA_TOKEN=<Profile → Security → long-lived access token>
#
#   ./download-backup.sh --list
#   ./download-backup.sh --latest ~/Downloads/ha.tar
#   ./download-backup.sh --slug abc123 ~/Downloads/ha.tar
#   ./download-backup.sh ~/Downloads/ha.tar          # create new backup, then download
set -euo pipefail

HA_URL="${HA_URL:-http://10.0.20.40:8123}"
OUT=""
MODE="create"
SLUG=""

require_token() {
  [[ -n "${HA_TOKEN:-}" ]] || {
    echo "Set HA_TOKEN (long-lived token from ${HA_URL}/profile/security)" >&2
    exit 1
  }
}
curl_auth() {
  require_token
  curl -sfS -H "Authorization: Bearer ${HA_TOKEN}" -H "Content-Type: application/json" "$@"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --list) MODE=list; shift ;;
    --latest) MODE=latest; shift; OUT="${1:-}"; shift || true ;;
    --slug) MODE=slug; SLUG="${2:?}"; shift 2; OUT="${1:-}"; shift || true ;;
    -h|--help)
      sed -n '2,12p' "$0"
      exit 0
      ;;
    *)
      OUT="$1"
      shift
      ;;
  esac
done

OUT="${OUT:-ha-backup-$(date +%Y%m%d-%H%M).tar}"

list_backups() {
  curl_auth "${HA_URL}/api/backups" | python3 -c "
import sys, json
data = json.load(sys.stdin)
backups = data if isinstance(data, list) else data.get('backups', data.get('data', []))
for b in backups:
    slug = b.get('slug') or b.get('backup_id') or b.get('id', '?')
    print(f\"{slug}\t{b.get('state','?')}\t{b.get('name', '')}\t{b.get('date', b.get('created', ''))}\")
if not backups:
    print('(no backups)', file=sys.stderr)
"

download_slug() {
  local slug="$1" dest="$2"
  echo "Downloading ${slug} → ${dest}"
  curl_auth -fSL -o "$dest" "${HA_URL}/api/backups/${slug}/download"
  echo "Saved ${dest}"
  echo "Analyze: ./analyze-backup.sh ${dest}"
}

case "$MODE" in
  list)
    echo "slug	state	name	date"
    list_backups
    exit 0
    ;;
  latest)
    slug="$(list_backups | awk '$2=="completed" || $2=="?" {print $1; exit}' | head -1)"
    [[ -n "$slug" ]] || { echo "No completed backup found. Create one in the UI or run without --latest." >&2; exit 1; }
    download_slug "$slug" "$OUT"
    exit 0
    ;;
  slug)
    download_slug "$SLUG" "$OUT"
    exit 0
    ;;
esac

echo "Creating new backup on ${HA_URL} (may take a few minutes)..."
# Home Assistant OS: core backup API is often missing; Supervisor can create but not download via token.
if curl_auth -o /dev/null -w "%{http_code}" "${HA_URL}/api/hassio/info" 2>/dev/null | grep -q 200; then
  echo "Detected Home Assistant OS — creating Supervisor backup (download from UI: Settings → System → Backups)."
  curl_auth -X POST -d '{}' "${HA_URL}/api/services/hassio/backup_full" >/dev/null
  echo "Open ${HA_URL} → Settings → System → Backups → download the newest .tar"
  echo "Then: ./analyze-backup.sh ~/Downloads/your-backup.tar"
  exit 0
fi

resp="$(curl_auth -X POST -d '{}' "${HA_URL}/api/services/backup/create" 2>&1)" || {
  echo "backup/create failed. Use UI: Settings → System → Backups." >&2
  echo "$resp" >&2
  exit 1
}

slug="$(echo "$resp" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
except json.JSONDecodeError:
    sys.exit(0)
if isinstance(d, list) and d:
    slug = d[0].get('slug') or d[0].get('backup_id')
elif isinstance(d, dict):
    slug = d.get('slug') or d.get('backup_id')
else:
    slug = None
print(slug or '')
" 2>/dev/null || true)"

if [[ -z "$slug" ]]; then
  echo "Waiting for newest backup to appear in list..."
  sleep 10
  slug="$(list_backups | tail -1 | awk '{print $1}')"
fi

[[ -n "$slug" ]] || { echo "Could not determine backup slug. Use: $0 --list" >&2; exit 1; }

echo "Backup slug=${slug}"
for _ in $(seq 1 72); do
  state="$(curl_auth "${HA_URL}/api/backups/${slug}" 2>/dev/null \
    | python3 -c "import sys,json; print(json.load(sys.stdin).get('state',''))" 2>/dev/null || echo "")"
  echo "  state=${state:-unknown}"
  [[ "$state" == "completed" ]] && break
  sleep 5
done

download_slug "$slug" "$OUT"
