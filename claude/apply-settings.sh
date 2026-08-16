#!/bin/bash -u
# Merge the shared Claude Code settings template (settings.common.json,
# tracked in dotfiles) with this machine's local overrides
# (settings.machine.json, gitignored — lives in the repo dir but is never
# committed) and write the result to settings.json (also gitignored).
#
# ln.sh symlinks settings.json (not settings.common.json) into ~/.claude, so
# ~/.claude/settings.json still shows up as a symlink into this repo.
#
# Keys that differ per machine (theme, enabledPlugins, extraKnownMarketplaces,
# alwaysThinkingEnabled, autoUpdatesChannel, ...) belong in settings.machine.json.
# Re-run this script after editing either input file.
set -euo pipefail

dir="$HOME/dotfiles/claude/.claude"
base="$dir/settings.common.json"
machine="$dir/settings.machine.json"
dest="$dir/settings.json"

if [ -f "$machine" ]; then
  jq -s '.[0] * .[1]' "$base" "$machine" > "$dest"
else
  cp "$base" "$dest"
fi
