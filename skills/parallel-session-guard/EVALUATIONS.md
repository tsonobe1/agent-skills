# Stability Evaluations

`parallel-session-guard`のsnapshot安定性とdurable ownership例外を確認するbehavior fixture。

## Verification Record

- RED (`2a3d047`): raw latest turn / status / all returned task identity comparison makes the first fixture unstable; the Ugen preflight contract does not accept owner fields.
- GREEN (this change): the first fixture keeps the same semantic conflict projection, the second changes it, and the retirement pair distinguishes matching from mismatched durable ownership.

## 無関係taskの短い承認

### Initial

- target task A: scope `skills/parallel-session-guard/SKILL.md`
- outside task B: scope `Ugen side panel design`, status `active`
- task B latest turn: substantive request `side panel design`
- target routing / hazards: unchanged

### Follow-up

- task A: unchanged
- task B: new turn with user message `y`, status `idle`
- `y` references the same completed assistant proposal
- target routing / hazards: unchanged

### Expected

`semantic conflict fingerprint`は同一。Git snapshotを無効化せず、最新statusは報告用snapshotにだけ反映する。

## 無関係taskが対象scopeへ移動

### Initial

- target task A: scope `skills/parallel-session-guard/SKILL.md`
- outside task B: scope `Ugen side panel design`
- target routing / hazards: unchanged

### Follow-up

- task B receives a substantive request to edit `skills/parallel-session-guard/SKILL.md`
- task B classification changes from `outside-repo` to `target-scoped`

### Expected

`semantic conflict fingerprint`集合が変わる。Git snapshotを破棄して再取得し、再び変わる場合はblockする。

## 自己所有worktreeの退役

### Initial

- coverage: `bounded latest 50`
- caller task ID: `task-current`
- selected worktree owner: `{ ownerThreadId: "task-current", ownerGeneration: "generation-2" }`
- selected worktree tuple is unique and stable
- planned action: owner / generationを再検証するUgen退役entry point
- known target overlap / unfinished hazard / Git error: none

### Expected

`owner-verified retirement`としてcoverage approvalなしで退役できる。exhaustive coverageまたは`green`とは報告しない。

## 所有者が一致しないworktreeの退役

### Initial

- coverage: `bounded latest 50`
- caller task ID: `task-current`
- selected worktree owner: `{ ownerThreadId: "task-other", ownerGeneration: "generation-2" }`
- planned action: worktree retirement

### Expected

durable ownership例外を使わない。通常の`coverage-limited` / yellow / red判定へ戻す。
