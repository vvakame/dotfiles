#!/bin/bash -u
# Generate the two Claude Code files that ln.sh symlinks into ~/.claude, by
# combining a shared template (tracked in dotfiles) with this machine's local
# overrides (gitignored — lives in the repo dir but is never committed):
#
#   settings.common.json + settings.machine.json -> settings.json
#   CLAUDE.common.md     + CLAUDE.machine.md     -> CLAUDE.md
#
# Both outputs are gitignored. ln.sh symlinks the generated files (not the
# .common ones), so ~/.claude/settings.json and ~/.claude/CLAUDE.md still show
# up as symlinks into this repo.
#
# What belongs in the machine-local half:
#   - keys that differ per machine (theme, enabledPlugins,
#     extraKnownMarketplaces, alwaysThinkingEnabled, autoUpdatesChannel, ...)
#   - anything that must not be published. This dotfiles repo is public, so
#     paths and instructions naming private repositories go in the machine
#     half regardless of whether they would otherwise be shared.
#
# Re-run this script after editing any input file.
set -euo pipefail

dir="$HOME/dotfiles/claude/.claude"
base="$dir/settings.common.json"
machine="$dir/settings.machine.json"
dest="$dir/settings.json"
md_base="$dir/CLAUDE.common.md"
md_machine="$dir/CLAUDE.machine.md"
md_dest="$dir/CLAUDE.md"

# jq's `*` merges objects recursively but REPLACES arrays, so a machine-local
# sandbox.filesystem.allowWrite would silently wipe the shared allowlist instead
# of extending it. Merge arrays as a union: common entries first, then the
# machine-only ones.
if [ -f "$machine" ]; then
  jq -s '
    def merge($a; $b):
      reduce ($b | to_entries[]) as {key: $k, value: $v} ($a;
        if ($a[$k] | type) == "object" and ($v | type) == "object" then
          .[$k] = merge($a[$k]; $v)
        elif ($a[$k] | type) == "array" and ($v | type) == "array" then
          .[$k] = ($a[$k] + ($v - $a[$k]))
        else
          .[$k] = $v
        end);
    merge(.[0]; .[1])
  ' "$base" "$machine" > "$dest"
else
  cp "$base" "$dest"
fi

# CLAUDE.md is prose, so there is nothing to merge key-wise: just concatenate,
# common first. Sections inside each input file are separated by a `---` rule,
# so emit one at the seam too — otherwise the file boundary is the only section
# break in the generated file without a rule.
if [ -f "$md_machine" ]; then
  { cat "$md_base"; printf '\n---\n\n'; cat "$md_machine"; } > "$md_dest"
else
  cp "$md_base" "$md_dest"
fi
