---
name: session-resume-check
description: Reconstruct current repo progress after reconnecting to a terminal or ssh session. Use when the user asks what has been done, what is uncommitted, what is verified, what changed since the last commit, or what the next safe step is after reconnecting.
---

# Session Resume Check

## Use When

Use this skill when the user asks what has been done, what is uncommitted, what is verified, what changed since the last commit, or what the next safe step is after reconnecting to a terminal, ssh session, or repo workspace.

Do not use this to start implementation. This skill reconstructs state and stops with the next safe action.

## Goal

ssh や terminal に再接続した直後に、今の repo がどこまで進んでいるかを短時間で復元する。

## Done

- current branch / ahead-behind is known
- committed progress and uncommitted progress are separated
- latest cheap verification status is reported as verified, unverified, or unavailable
- unrelated local noise is separated from task work
- the next safe action is one concrete step

## Stop

Stop without editing when:

- the user only asked for status or next action
- the repo identity, cwd, worktree, or branch does not match the expected task context
- the next action would require review, commit, push, destructive cleanup, or broad implementation approval

## Use This Skill For

- `今どこまで進んだ?`
- `現状確認して`
- `続きから始めたい`
- `何が commit 済みで何が未 commit か見て`
- `前回どこで止まったか整理して`
- `次に何をするのが安全か教えて`

## Outputs

- current branch / ahead-behind
- committed progress
- uncommitted progress
- latest cheap verification result if available
- unrelated local noise
- next safe action

## Workflow

1. まず current fact を集める。
   - `git status --short --branch`
   - `git diff --stat`
   - `git log --oneline -n 5`
2. 変更ファイルを分ける。
   - task 本体の差分
   - local state や editor backup の差分
   - 未追跡の一時ファイル
3. 必要なら差分の中身を読む。
   - `git diff -- <relevant-files>`
   - 直近 commit の要約が必要なら `git show --stat --oneline <commit>`
4. cheap verification が分かる repo なら実行する。
   - 既存の smoke / unit / lint のうち、安くて意味のあるものを 1 つ選ぶ
   - repo 固有 skill があるなら、その skill の verification ルールを優先する
5. 編集は始めずに、現状だけを要約する。

## Decision Rules

- まず raw fact を出す。推測は後段に分ける
- `history`、swap、backup、cache、生成された local state は task 本体と混ぜない
- cheap verification が不明なら、無理に走らせず `未確認` と明示する
- `今どういう状況` の依頼では、勝手に実装に進まない
- 次の一手は 1 つに絞る

## Reporting Format

結果は短く、次の順で返す。

1. いま何ができているか
2. 何が未 commit か
3. 検証済みか未確認か
4. task 本体ではないノイズ
5. 次の安全な一手

## Notes

- repo 固有 skill があるときは、現状確認の解釈にだけ併用してよい
- `git status --short --branch` と `git diff --stat` だけで十分なときは、それ以上広げない
- `何をしたのか` と `今何ができるのか` を先に答える

## Invocation

ユーザが次のように言ったら、この skill を使う。

- `session-resume-check で見て`
- `ssh reconnect したので現状確認して`
- `今どこまで進んだか見て`
- `続きから始めたいので状況整理して`
- `今どういう状況`
