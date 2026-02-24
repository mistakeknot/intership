---
allowed-tools: Read, Edit, Write, Bash, AskUserQuestion
description: Customize Culture ship spinner verbs — pick books, add/remove ships, toggle mode
user-invocable: true
---

# Intership Setup

You are configuring the Culture ship name spinner verbs for Claude Code.

## What to do

1. Read the current ship list from `${CLAUDE_PLUGIN_ROOT}/data/ships.txt`
2. Read the current settings from `~/.claude/settings.json` (the `spinnerVerbs` key)
3. Ask the user what they want to change:
   - **Filter by book**: Only include ships from specific novels (comments in ships.txt mark which book each group is from)
   - **Add custom ships**: User can add their own Culture ship names
   - **Remove ships**: User can remove specific ships they don't want
   - **Toggle mode**: Switch between "replace" (only ships) and "append" (ships + defaults)
4. Update `data/ships.txt` with the changes
5. Re-run the session-start hook to apply: `bash ${CLAUDE_PLUGIN_ROOT}/hooks/session-start.sh`
6. Confirm what changed and tell the user: **Restart Claude Code (`/exit` then relaunch) to see the new spinner verbs.** Claude Code reads spinner verbs at launch, so changes written to settings.json during a session won't appear until the next session.
