#!/usr/bin/env bash
# Summarize a running Home Assistant (no backup file needed) — pick what to migrate.
#
#   export HA_URL=http://10.0.20.40:8123
#   export HA_TOKEN=<Profile → Security → long-lived access token>
#   ./inspect-live.sh
set -euo pipefail

HA_URL="${HA_URL:-http://10.0.20.40:8123}"
HA_TOKEN="${HA_TOKEN:?Set HA_TOKEN — create at ${HA_URL}/profile/security}"

auth=(-H "Authorization: Bearer ${HA_TOKEN}" -H "Content-Type: application/json")

api() {
  curl -sfS "${auth[@]}" "${HA_URL}$1"
}

echo "=== Home Assistant live summary ==="
echo "URL: ${HA_URL}"
echo

echo "--- Server ---"
api /api/config | python3 -c "
import sys, json
c = json.load(sys.stdin)
for k in ('version', 'location_name', 'time_zone', 'unit_system', 'state'):
    if k in c: print(f'  {k}: {c[k]}')
"

echo
echo "--- Integrations (config entries) ---"
api /api/config/config_entries/entry 2>/dev/null | python3 -c "
import sys, json
entries = json.load(sys.stdin)
by_domain = {}
for e in entries:
    d = e.get('domain', '?')
    by_domain.setdefault(d, []).append(e.get('title') or e.get('entry_id', '?'))
for d in sorted(by_domain):
    titles = by_domain[d]
    print(f'  {d} ({len(titles)}):')
    for t in titles[:8]:
        print(f'    - {t}')
    if len(titles) > 8:
        print(f'    … +{len(titles)-8} more')
print(f'  Total entries: {len(entries)}')
" || echo "  (config_entries API unavailable — use backup analyze instead)"

echo
echo "--- Entities by domain (top 20) ---"
api /api/states | python3 -c "
import sys, json
from collections import Counter
states = json.load(sys.stdin)
domains = Counter(s['entity_id'].split('.')[0] for s in states)
print(f'  Total entities: {len(states)}')
for dom, n in domains.most_common(20):
    print(f'  {dom}: {n}')
"

echo
echo "--- Automations ---"
api /api/states | python3 -c "
import sys, json
states = [s for s in json.load(sys.stdin) if s['entity_id'].startswith('automation.')]
print(f'  Count: {len(states)}')
for s in sorted(states, key=lambda x: x['entity_id'])[:30]:
    name = s['attributes'].get('friendly_name', s['entity_id'])
    print(f'    {s[\"entity_id\"]}  ({name})')
if len(states) > 30:
    print(f'    … +{len(states)-30} more')
"

echo
echo "--- Existing backups on server ---"
api /api/backups 2>/dev/null | python3 -c "
import sys, json
data = json.load(sys.stdin)
backups = data if isinstance(data, list) else data.get('backups', data.get('data', []))
if not backups:
    print('  (none listed)')
    sys.exit(0)
for b in backups:
    slug = b.get('slug') or b.get('backup_id') or b.get('id', '?')
    name = b.get('name', slug)
    state = b.get('state', '?')
    size = b.get('size', b.get('size_mb', ''))
    created = b.get('date') or b.get('created') or ''
    print(f'  [{state}] {name}  slug={slug}  {created}  {size}')
print(f'  Total: {len(backups)}')
print('  Download one: ./download-backup.sh --slug <slug> ~/Downloads/ha.tar')
" || echo "  (backups API unavailable on this version)"

echo
echo "Next: ./download-backup.sh ~/Downloads/ha-$(date +%Y%m%d).tar"
echo "       ./analyze-backup.sh ~/Downloads/ha-*.tar"
