# intership

Replaces Claude Code's default spinner verbs with Culture ship names from Iain M. Banks' novels.

## How it works

- **Session-start hook** reads `data/ships.txt`, writes `spinnerVerbs` to `~/.claude/settings.json`
- **`/intership:setup` command** lets users filter by book, add/remove ships, toggle mode
- Ship names are stored one-per-line in `data/ships.txt` with `#` comment headers marking source novels

## Files

- `data/ships.txt` — ship name database (editable)
- `data/config.json` — canonical/generated toggle
- `data/generator-prompt.md` — v6 prompt for generating new ship names (iteratively refined over 6 rounds)
- `hooks/session-start.sh` — reads ships, merges into settings.json
- `commands/setup.md` — interactive customization command
