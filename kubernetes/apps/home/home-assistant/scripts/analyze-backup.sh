#!/usr/bin/env bash
# Unpack a Home Assistant .tar backup and print an inventory (no cluster changes).
#
#   ./analyze-backup.sh ~/Downloads/Automatic_backup_2026.tar
set -euo pipefail

INPUT="${1:?Usage: $0 <backup.tar>}"
workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT

echo "=== Analyzing: $INPUT ==="
tar -xf "$INPUT" -C "$workdir"

config_dir="$workdir"
if [[ -f "$workdir/homeassistant.tar.gz" ]]; then
  mkdir -p "$workdir/config"
  tar -xzf "$workdir/homeassistant.tar.gz" -C "$workdir/config"
  config_dir="$workdir/config"
elif [[ -f "$workdir/data.tar.gz" ]]; then
  mkdir -p "$workdir/config"
  tar -xzf "$workdir/data.tar.gz" -C "$workdir/config"
  config_dir="$workdir/config"
fi

if [[ ! -f "$config_dir/configuration.yaml" ]]; then
  echo "Could not find configuration.yaml. Archive layout:"
  find "$workdir" -maxdepth 3 \( -type f -o -type d \) | head -40
  exit 1
fi

echo
echo "--- Top-level /config ---"
ls -la "$config_dir" | awk '{print "  "$0}'

echo
echo "--- configuration.yaml (includes / packages only; secrets redacted) ---"
python3 - "$config_dir/configuration.yaml" <<'PY'
import re, sys
path = sys.argv[1]
for line in open(path, errors="replace"):
    if re.search(r"(?i)(password|token|api_key|client_secret|private_key|credential)", line):
        key = line.split(":")[0] if ":" in line else line[:40]
        print(f"  {key.strip()}: ***")
    else:
        print(f"  {line.rstrip()}"[:200])
PY

if [[ -d "$config_dir/packages" ]]; then
  for f in "$config_dir"/packages/*.yaml; do
    [[ -f "$f" ]] || continue
    echo
    echo "--- packages/$(basename "$f") (first 40 lines, secrets redacted) ---"
    python3 - "$f" <<'PY'
import re, sys
for i, line in enumerate(open(sys.argv[1], errors="replace")):
    if i >= 40: print("  …"); break
    if re.search(r"(?i)(password|token|api_key|secret)", line):
        print(f"  {line.split(':')[0].strip()}: ***")
    else:
        print(f"  {line.rstrip()}"[:200])
PY
  done
fi

echo
echo "--- Integrations (.storage/core.config_entries) ---"
if [[ -f "$config_dir/.storage/core.config_entries" ]]; then
  python3 - "$config_dir/.storage/core.config_entries" <<'PY'
import json, sys
from collections import defaultdict
raw = open(sys.argv[1]).read()
# HA storage file is JSON with "data" -> "entries"
data = json.loads(raw)
entries = data.get("data", {}).get("entries", data.get("entries", []))
by = defaultdict(list)
for e in entries:
    by[e.get("domain","?")].append(e.get("title") or e.get("entry_id","?"))
for d in sorted(by):
    print(f"  {d} ({len(by[d])}):")
    for t in by[d][:6]:
        print(f"    - {t}")
    if len(by[d]) > 6:
        print(f"    … +{len(by[d])-6}")
print(f"  Total: {len(entries)}")
PY
else
  echo "  (not in backup)"
fi

echo
echo "--- Automations ---"
if [[ -d "$config_dir/automations" ]]; then
  echo "  Directory automations/:"
  ls "$config_dir/automations" | sed 's/^/    /'
elif [[ -f "$config_dir/automations.yaml" ]]; then
  grep -E '^[[:space:]]*-[[:space:]]*(id|alias):' "$config_dir/automations.yaml" | head -40 | sed 's/^/  /'
else
  echo "  (check packages/ or configuration.yaml automation: !include)"
fi

echo
echo "--- Scripts / scenes ---"
[[ -f "$config_dir/scripts.yaml" ]] && echo "  scripts.yaml: $(grep -c '^  - ' "$config_dir/scripts.yaml" 2>/dev/null || echo present)"
[[ -f "$config_dir/scenes.yaml" ]] && echo "  scenes.yaml: present"
[[ -d "$config_dir/custom_components" ]] && echo "  custom_components: $(ls "$config_dir/custom_components" | tr '\n' ' ')"

echo
echo "--- Entity registry (counts by domain) ---"
if [[ -f "$config_dir/.storage/core.entity_registry" ]]; then
  python3 - "$config_dir/.storage/core.entity_registry" <<'PY'
import json, sys
from collections import Counter
data = json.loads(open(sys.argv[1]).read())
ents = data.get("data", {}).get("entities", [])
domains = Counter(e["entity_id"].split(".")[0] for e in ents)
print(f"  Registered entities: {len(ents)}")
for d, n in domains.most_common(15):
    print(f"    {d}: {n}")
PY
fi

echo
echo "--- Disk usage (largest under /config) ---"
du -sh "$config_dir"/* 2>/dev/null | sort -hr | head -15 | sed 's/^/  /'

echo
echo "=== Done ==="
echo "To migrate everything: ./restore-config.sh \"$INPUT\""
echo "To cherry-pick: extract tarball, copy only chosen files into a folder, then:"
echo "  ./restore-config.sh /path/to/your/partial/config"
