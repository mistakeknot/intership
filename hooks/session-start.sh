#!/usr/bin/env bash
set -euo pipefail

PLUGIN_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SETTINGS_FILE="$HOME/.claude/settings.json"
SHIPS_FILE="$PLUGIN_ROOT/data/ships.txt"
CONFIG_FILE="$PLUGIN_ROOT/data/config.json"

# Read config — defaults to both canonical and generated
include_canonical=true
include_generated=true
if [[ -f "$CONFIG_FILE" ]] && command -v jq &>/dev/null; then
    include_canonical=$(jq -r 'if has("includeCanonical") then .includeCanonical else true end' "$CONFIG_FILE")
    include_generated=$(jq -r 'if has("includeGenerated") then .includeGenerated else true end' "$CONFIG_FILE")
fi

# Read ship names, skip comments and blank lines, deduplicate
mapfile -t ships < <(grep -v '^#' "$SHIPS_FILE" | grep -v '^[[:space:]]*$' | sort -u)

if [[ ${#ships[@]} -eq 0 ]]; then
    echo "intership: no ship names found in $SHIPS_FILE" >&2
    exit 0
fi

# Build JSON array of ship names, filtering by config
json_array="["
first=true
canonical_count=0
generated_count=0
for i in "${!ships[@]}"; do
    # Trim leading/trailing whitespace (xargs chokes on apostrophes)
    name="${ships[$i]#"${ships[$i]%%[![:space:]]*}"}"
    name="${name%"${name##*[![:space:]]}"}"
    [[ -z "$name" ]] && continue

    # Check if canonical (wrapped in *asterisks*) or generated
    if [[ "$name" == \** && "$name" == *\* ]]; then
        [[ "$include_canonical" != "true" ]] && continue
        canonical_count=$((canonical_count + 1))
    else
        [[ "$include_generated" != "true" ]] && continue
        generated_count=$((generated_count + 1))
    fi

    # Escape quotes for JSON
    name="${name//\\/\\\\}"
    name="${name//\"/\\\"}"
    if [[ "$first" == true ]]; then
        first=false
    else
        json_array+=","
    fi
    json_array+="\"$name\""
done
json_array+="]"

total=$((canonical_count + generated_count))
if [[ $total -eq 0 ]]; then
    echo "intership: no ships matched current filter (canonical=$include_canonical, generated=$include_generated)" >&2
    exit 0
fi

# Ensure settings file exists
mkdir -p "$(dirname "$SETTINGS_FILE")"
if [[ ! -f "$SETTINGS_FILE" ]]; then
    echo '{}' > "$SETTINGS_FILE"
fi

# Use jq if available, otherwise python3
if command -v jq &>/dev/null; then
    tmp=$(mktemp)
    jq --argjson verbs "$json_array" '.spinnerVerbs = {"mode": "replace", "verbs": $verbs}' "$SETTINGS_FILE" > "$tmp"
    mv "$tmp" "$SETTINGS_FILE"
elif command -v python3 &>/dev/null; then
    python3 -c "
import json, sys
with open('$SETTINGS_FILE') as f:
    data = json.load(f)
data['spinnerVerbs'] = {'mode': 'replace', 'verbs': json.loads(sys.argv[1])}
with open('$SETTINGS_FILE', 'w') as f:
    json.dump(data, f, indent=2)
" "$json_array"
else
    echo "intership: needs jq or python3 to update settings" >&2
    exit 0
fi

echo "intership: loaded $total spinner verbs ($canonical_count canonical, $generated_count generated) — restart session to see them"
