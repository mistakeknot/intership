#!/usr/bin/env bash
set -euo pipefail

PLUGIN_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SETTINGS_FILE="$HOME/.claude/settings.json"
SHIPS_FILE="$PLUGIN_ROOT/data/ships.txt"

# Read ship names, skip comments and blank lines, deduplicate
mapfile -t ships < <(grep -v '^#' "$SHIPS_FILE" | grep -v '^[[:space:]]*$' | sort -u)

if [[ ${#ships[@]} -eq 0 ]]; then
    echo "intership: no ship names found in $SHIPS_FILE" >&2
    exit 0
fi

# Build JSON array of ship names
json_array="["
first=true
for i in "${!ships[@]}"; do
    # Trim leading/trailing whitespace (xargs chokes on apostrophes)
    name="${ships[$i]#"${ships[$i]%%[![:space:]]*}"}"
    name="${name%"${name##*[![:space:]]}"}"
    [[ -z "$name" ]] && continue
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

echo "intership: loaded ${#ships[@]} Culture ship names as spinner verbs"
