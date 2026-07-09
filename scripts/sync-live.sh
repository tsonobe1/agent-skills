#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
skills_dir="$repo_root/skills"

codex_home="${CODEX_HOME:-$HOME/.codex}"
claude_home="${CLAUDE_HOME:-$HOME/.claude}"
grok_home="${GROK_HOME:-$HOME/.grok}"
codex_skills_dir="$codex_home/skills"
claude_skills_dir="$claude_home/skills"
grok_skills_dir="$grok_home/skills"

codex_state="$codex_skills_dir/.agent-skills-managed"
codex_file_state="$codex_skills_dir/.agent-skills-managed-files"
claude_state="$claude_skills_dir/.agent-skills-managed"
grok_state="$grok_skills_dir/.agent-skills-managed"

mkdir -p "$codex_skills_dir" "$claude_skills_dir" "$grok_skills_dir"

current_codex="$(mktemp)"
current_codex_files="$(mktemp)"
current_claude="$(mktemp)"
current_grok="$(mktemp)"
trap 'rm -f "$current_codex" "$current_codex_files" "$current_claude" "$current_grok"' EXIT

find "$skills_dir" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort > "$current_codex"
find "$skills_dir" -mindepth 1 -maxdepth 1 -type f -exec basename {} \; | sort > "$current_codex_files"

replace_with_symlink() {
  local target="$1"
  local source="$2"

  if [ -L "$target" ]; then
    local existing
    existing="$(readlink "$target")"
    if [ "$existing" = "$source" ]; then
      return
    fi
  fi

  rm -rf "$target"
  ln -s "$source" "$target"
}

while IFS= read -r skill_name; do
  [ -n "$skill_name" ] || continue
  replace_with_symlink "$codex_skills_dir/$skill_name" "$skills_dir/$skill_name"
done < "$current_codex"

while IFS= read -r file_name; do
  [ -n "$file_name" ] || continue
  replace_with_symlink "$codex_skills_dir/$file_name" "$skills_dir/$file_name"
done < "$current_codex_files"

if [ -f "$codex_state" ]; then
  while IFS= read -r old_skill; do
    [ -n "$old_skill" ] || continue
    if ! grep -Fxq "$old_skill" "$current_codex"; then
      rm -rf "$codex_skills_dir/$old_skill"
    fi
  done < "$codex_state"
fi
cp "$current_codex" "$codex_state"

if [ -f "$codex_file_state" ]; then
  while IFS= read -r old_file; do
    [ -n "$old_file" ] || continue
    if ! grep -Fxq "$old_file" "$current_codex_files"; then
      rm -rf "$codex_skills_dir/$old_file"
    fi
  done < "$codex_file_state"
fi
cp "$current_codex_files" "$codex_file_state"

while IFS= read -r skill_name; do
  [ -n "$skill_name" ] || continue
  echo "$skill_name"
  replace_with_symlink "$claude_skills_dir/$skill_name" "$skills_dir/$skill_name"
done < "$current_codex" > "$current_claude"

if [ -f "$claude_state" ]; then
  while IFS= read -r old_skill; do
    [ -n "$old_skill" ] || continue
    if ! grep -Fxq "$old_skill" "$current_claude"; then
      rm -rf "$claude_skills_dir/$old_skill"
    fi
  done < "$claude_state"
fi
cp "$current_claude" "$claude_state"

while IFS= read -r skill_name; do
  [ -n "$skill_name" ] || continue
  echo "$skill_name"
  replace_with_symlink "$grok_skills_dir/$skill_name" "$skills_dir/$skill_name"
done < "$current_codex" > "$current_grok"

if [ -f "$grok_state" ]; then
  while IFS= read -r old_skill; do
    [ -n "$old_skill" ] || continue
    if ! grep -Fxq "$old_skill" "$current_grok"; then
      rm -rf "$grok_skills_dir/$old_skill"
    fi
  done < "$grok_state"
fi
cp "$current_grok" "$grok_state"

echo "Synced $(wc -l < "$current_codex" | tr -d ' ') Codex skills, $(wc -l < "$current_codex_files" | tr -d ' ') Codex top-level files, $(wc -l < "$current_claude" | tr -d ' ') Claude skills, and $(wc -l < "$current_grok" | tr -d ' ') Grok skills."
