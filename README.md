# Agent Skills

Shared skills for Codex and Claude.

This repository is the source of truth for personal agent skills. Runtime skill
directories are symlinks into this repo:

- `~/.codex/skills/<name> -> ./skills/<name>`
- `~/.claude/skills/<name> -> ./skills/<name>`

## Sync

Run:

```sh
./scripts/sync-live.sh
```

The sync script:

- links every directory under `skills/` into `~/.codex/skills`
- links every directory under `skills/` into `~/.claude/skills`
- records the managed names in `.agent-skills-managed`
- prunes names that were previously managed by this repo but no longer exist

It does not touch unrelated runtime skills such as Codex system skills, plugin
skills, or other personal skill repositories.

## Updating Upstream Skills

For upstream updates such as `mattpocock/skills`, treat the update as a merge:

1. Clone the upstream release or main branch into a temporary directory.
2. Copy or merge the relevant skill directories into `skills/`.
3. Keep local compatibility aliases when old prompts still use old names.
4. Run `./scripts/sync-live.sh`.
5. Review, commit, and push this repository.
