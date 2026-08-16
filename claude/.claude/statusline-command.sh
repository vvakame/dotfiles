#!/bin/bash
# Claude Code statusLine command
#
# Plain text, no ANSI colors. Comma-separated fields, each field except the
# bare model name is prefixed with a "label:" tag:
#   1. model name                (no label)
#   2. ctx: <used%>              (context window usage)
#   3. dir: <cwd, home-relative> (`.workspace.current_dir` with the resolved
#                                 home directory prefix replaced by `~`; if
#                                 cwd isn't under the home dir, shown as-is)
#   4. wt&branch: <name>         (when worktree dir name == branch name)
#      -- or, when they differ --
#      wt: <worktree>, branch: <branch>
#
# Any field whose data is unavailable is omitted entirely; no stray/doubled
# separators are left behind.

input=$(cat)

model_name=$(echo "$input" | jq -r '.model.display_name // empty')
context_used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
cwd=$(echo "$input" | jq -r '.workspace.current_dir // empty')

# dir field: home-relative path (`~/...`).
#
# Two bugs had to be fixed to get here:
# 1. `${cwd/#$HOME/~}` relies on $HOME being set in the environment the
#    statusLine command runs in, and Claude Code invokes it in a sanitized
#    subprocess environment where $HOME is not set/exported. Fixed by
#    resolving the home dir via bash's own tilde expansion (`eval echo ~`),
#    which falls back to a passwd-database lookup when $HOME is unset.
# 2. Even with the right home_dir, `${cwd/#$home_dir/~}` silently no-ops:
#    the unquoted `~` in the replacement slot is itself tilde-expanded by
#    bash back into the home dir path, so the prefix gets replaced with
#    itself. Fixed by quoting it: `"~"`.
home_dir=$(eval echo ~)
[ -z "$home_dir" ] && home_dir="$HOME"

dir_display="$cwd"
if [ -n "$cwd" ] && [ -n "$home_dir" ]; then
  dir_display="${cwd/#$home_dir/"~"}"
fi

worktree=""
branch=""
if git -C "$cwd" --no-optional-locks rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  worktree_root=$(git -C "$cwd" --no-optional-locks rev-parse --show-toplevel 2>/dev/null)
  if [ -n "$worktree_root" ]; then
    worktree=$(basename "$worktree_root")
  fi
  branch=$(git -C "$cwd" --no-optional-locks branch --show-current 2>/dev/null)
fi

fields=()

[ -n "$model_name" ] && fields+=("$model_name")

if [ -n "$context_used" ]; then
  ctx_str=$(printf '%.0f' "$context_used")
  fields+=("ctx: ${ctx_str}%")
fi

[ -n "$dir_display" ] && fields+=("dir: ${dir_display}")

if [ -n "$worktree" ] || [ -n "$branch" ]; then
  if [ -n "$worktree" ] && [ "$worktree" = "$branch" ]; then
    fields+=("wt&branch: ${worktree}")
  else
    [ -n "$worktree" ] && fields+=("wt: ${worktree}")
    [ -n "$branch" ] && fields+=("branch: ${branch}")
  fi
fi

output=""
if [ "${#fields[@]}" -gt 0 ]; then
  output=$(printf "%s, " "${fields[@]}")
  output="${output%, }"
fi

printf "%s" "$output"
