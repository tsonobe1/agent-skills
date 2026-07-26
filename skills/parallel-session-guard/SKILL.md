---
name: parallel-session-guard
description: Use when work may overlap another Codex session, branch, worktree, or changed file; when active session ownership must be checked; or when follow-up work may need to be queued to an existing owning session.
---

# Objective

複数の Codex セッションを同時に進める前に、最近の作業と現在の Git 状態を照合し、競合しにくい作業領域を決める。

**Core principle:** 同じbranch、編集領域、または設計責任の所有者を増やさない。ファイルの重複だけでは競合と断定せず、変更するsymbol・責務・仕様を比較する。所有セッションが実行中なら、そのturnを中断せず、ユーザーへ説明してから後続キューへ積む。

# Use This Skill For

- `並列で進めたい`
- `今アクティブな session を確認して`
- `main で何をやっているか確認して`
- `このタスクが既存作業とぶつからないか見て`
- `安全な worktree / branch を切って`
- `担当ファイルを予約したい`

# Outputs

- recent session inventory
- worktree / branch inventory
- overlap assessment
- recommendation:
  - existing worktree を再利用する
  - 新しい worktree を切る
  - clean な worktree に新しい branch を切る
  - owning session の後続キューへ積む
  - 競合が強いので確認待ちにする

# Canonical Sources

- Ugenの`scripts/worktrees/preflight.mjs`: baseline、登録worktree、変更分類、file overlap
- Codex appの`list_threads`: taskの`status`, ID, `hostId`, `cwd`, title
- Codex appの`read_thread`: 候補taskの現在scopeとturn内容
- Codex appの`wait_threads`: bounded snapshot、event cursor、新しい進捗の待機
- Gitのrepository identity: repo rootとtask `cwd`が同じrepositoryに属するかの確認だけ
- Ugen preflightが存在しないcheckoutでのみ、Gitのworktree、branch、dirty state、diff

`~/.codex/sessions`などの内部ログや更新時刻から、taskのactive状態や所有者を推測しない。Codex appのtask情報を確認できない場合は、正確な依頼先を特定できないものとして送信を止め、ユーザーへ報告する。

repository identityの確認では、repo rootと各task `cwd`のcanonical common Git directoryだけを比較する。これはtaskのrepo所属を絞るための確認であり、branch、worktree一覧、HEAD、dirty state、diffを収集しない。task `cwd`のidentityを解決できない場合は、そのtaskをrepo inventoryへ含めず`unscoped`として報告する。

```sh
git -C <cwd> rev-parse --path-format=absolute --git-common-dir
```

Git snapshot取得後にtask `cwd`をworktreeへ対応付けるときは、task `cwd`と各worktree pathをcanonical absolute pathへ正規化し、path separator境界を含む包含判定を行う。`cwd`と同一、または`cwd`を含む候補のうち最長pathを選ぶ。候補なし、canonicalize失敗、同じ長さの候補が複数ある場合はtaskを`unscoped`としてfail closedにする。文字列prefixだけで`/repo`を`/repo-other`へ対応付けない。

# Ugen Preflight

repo rootを解決し、正確なpathの存在確認が成功して`scripts/worktrees/preflight.mjs`が存在する場合は、repo-scoped taskの最後の`read_thread`直後に、個別Git状態確認より先に、repo rootから引数なしで1回だけ実行する。task確認とpreflightの間に別の調査や判断を挟まない。実行前にmonotonic clockで120秒後のdeadlineを記録し、独立してterminateできるjobとして開始する。deadlineまでpollし、未完了なら実行toolのterminate機能でjobのprocess treeを強制終了して、停止済みを確認する。この制御を保証できない場合は実行せずfail closedとする。

```sh
# execution tool: hard timeout 120 seconds; terminate process tree on expiry
./scripts/worktrees/preflight.mjs
```

timeoutまたは強制終了は1回の実行を消費した契約違反とし、再実行も個別Git確認へのfallbackも行わない。

開始判断に使えるのは、終了codeが`0`で、stdoutが1個のarrayではないnon-null objectとしてparseでき、次の型契約をすべて満たす場合だけとする。

- `schemaVersion === 1`、`complete === true`、`refreshed === true`
- `baseline`はobject、`ref === "origin/main"`、`sha`は空でないstring
- `worktrees`はobjectのarray。`path`と`head`はstring、`branch`、`lockReason`、`prunableReason`はstringまたは`null`、`detached`、`locked`、`prunable`はboolean
- 各`changes`はobjectで、`committed`、`staged`、`unstaged`、`untracked`、`allPaths`はstringのarray
- `fileOverlaps`はobjectのarrayで、各`worktreePaths`と`paths`はstringのarray
- `errors`はobjectのarrayで、各`code`と`message`、任意の`worktreePath`はstring。開始判断時は空

scriptが存在するのに、実行失敗、非zero終了、JSON parse失敗、型不正、未知のschema、欠けたkey、`complete: false`、`refreshed: false`のいずれかになった場合はfail closedとする。個別Git commandへfallbackして開始可能と判定してはならない。

従来の個別Git確認へfallbackできるのは、repo rootの解決に成功した後、正確なscript pathの存在確認が`ENOENT`を返した場合だけとする。権限、I/O、root解決、script実行時の`ENOENT`を含む他の失敗はすべてfail closedとする。validなpreflightの`changes`を対応worktreeのGit差分証拠として使い、同じ状態を個別commandで再収集しない。

# Fallback Git Snapshot

fallbackでは、repo instructionsまたはユーザーが明示したcanonical baselineを優先する。明示baselineがない場合は、remoteのsymbolic default refが一意でcommitに解決できるときだけ、そのrefと固定したSHAをbaselineにする。`origin/main`、`main`、`trunk`、current branch、最初に見つかったremoteを推測で選ばない。baseline refまたはSHAが解決不能、複数候補、dangling、unbornならGit証拠を不完全としてfail closedにする。

全worktreeでHEAD SHAを固定し、named / detached、clean / dirty、live taskの有無にかかわらず、committed pathsを同じ比較で収集する。

```sh
git diff --name-only <baseline-sha>...<worktree-head-sha>
```

merge base、worktree HEAD、diff、statusのいずれかを解決できないworktreeが1つでもあればsnapshot全体を不完全とする。detached worktreeもcommitted pathsとdirty pathsを収集対象に含めるが、作業領域として再利用しない。

# Workflow

1. repo rootとrepository identityだけを解決する。この時点ではbranch、worktree一覧、HEAD、dirty state、diffを個別Git commandで収集しない。
2. 正確なscript path lookupの結果を、存在、`ENOENT`、その他のinspection errorに分類する。この時点ではpreflightもfallback Git状態収集もまだ実行しない。
3. `list_threads`をqueryなしで呼び、各task `cwd`のrepository identityをrepo rootと比較する。一致したtaskだけをrepo-scoped候補とし、identityを解決できないtaskは`unscoped`として分ける。tool responseがpartial、truncated、またはsource unavailableを示す場合はtask inventoryを不完全とする。
4. repo-scoped候補を対象に`wait_threads`の`timeoutMs: 0` snapshotを取り、各taskのevent cursorを保存する。
5. repo-scoped候補を`read_thread`で確認し、ID、`hostId`、live `status`、現在scopeを特定する。
6. 最後の`read_thread`直後に、scriptが存在する場合は120秒のhard deadlineでUgen preflightを1回実行して契約を検証する。invalidまたはtimeoutならGit証拠を不完全として開始・競合判定をblockする。
7. path lookupが`ENOENT`を返した場合だけ、最後の`read_thread`直後にfallback Git snapshotを集める。
   - `git status --short --branch`
   - `git worktree list --porcelain`
   - 各 worktree について `git -C <worktree> status --short --branch`
8. fallbackではbaseline ref / SHAと全worktreeのHEAD SHAを固定し、各HEADのcommitted pathsとstatus由来のstaged / unstaged / untracked pathsを収集する。
9. preflightまたはfallback Git snapshot後、先に`list_threads`とrepository identityの対応付けを再取得し、repo-scoped taskの追加・消失・status変化がないことを確かめる。次に保存したcursorを`afterCursor`に指定して`wait_threads`の`timeoutMs: 0` snapshotを取り、task確認後のstatus / scope更新がないことを最後に確かめる。いずれかに差分があればtaskとGitの証拠を同一時点のものと扱わず、開始判断をblockしてguardのやり直しが必要と報告する。
10. taskの`cwd`をcanonical absolute worktree pathへ境界付き最長一致で対応付ける。対応不能または同長の複数候補は`unscoped`とする。validなpreflightでは`changes`をGit差分証拠、`fileOverlaps`を既存worktree同士の重複候補抽出に使うが、それだけで競合と断定しない。
11. Git証拠またはtask inventoryが不完全な場合と、`unscoped` taskが残る場合は、契約違反、repo-scoped task inventory、`unscoped` taskを分けて報告し停止する。inventoryをcompleteと呼ばず、開始・競合判定・作業領域提案は行わない。
12. 新しい作業の予定file、symbol、責務、仕様を、live taskとの対応有無にかかわらず、変更のある全worktreeの`changes`と比較する。
13. live taskの現在scopeも加えてgreen / yellow / redを判定する。
14. 安全な作業領域を提案する。ユーザーが作成まで求めたら、その場でbranch / worktreeを作る。
15. `red`でも同じ所有taskが続けるのが適切なら、新しい作業領域を作らず、global `AGENTS.md`の後続依頼ルールに従う。

# Conflict Levels

- `green`
  - 別 worktree で、対象ファイルと feature area が重ならない
- `yellow`
  - 同じファイルでも、変更するsymbol・責務・仕様が分離している
  - 同じ module や shared test / docs に触る
  - separate worktree、編集領域のownership、統合順序の明示が前提
- `red`
  - 同じbranchまたは同じworktreeを複数sessionで編集しようとしている
  - 同じ関数、型、プロパティ、または密接に結合したコード領域を変更する
  - 同じ仕様、責務、設計判断、またはfeatureを別sessionが進めている
  - 一方が対象ファイル全体の整形、分割、移動、生成を行う
  - dirtyなdetached worktreeが同じ編集領域を触っている

# Quick Reference

| State | Action |
| --- | --- |
| `green` | 独立した作業領域で進める |
| `yellow` | 別worktreeで編集領域と統合順序を明示して進める |
| `red`かつ既存所有セッションが続ける | ユーザーへ事前説明し、所有セッションの後続キューへ積む |
| `red`かつ所有者・scope・キュー動作が不明 | 送信も編集もせずユーザーへ確認する |

## Same-File Decision

同じファイルという事実は警告信号であり、それだけでは`red`にしない。

| Overlap | Level |
| --- | --- |
| 別の関数・型・責務を変更し、仕様上も独立している | `yellow` |
| 実装と、その変更領域に直接依存しないテストを変更する | `yellow` |
| 同じsymbol、密接に結合した挙動、同じ設計判断を変更する | `red` |
| ファイル全体の整形、分割、移動、生成が含まれる | `red` |
| 予定するsymbol・責務を特定できず、独立性を確認できない | scopeを明確にするまで`red` |

# Decision Rules

- 並列作業が quick review で終わらないなら、同じ worktree ではなく別 worktree を優先する。
- 新タスクが local `main` の未 push / 未 merge 変更に依存するなら、`origin/main` ではなく current `main` から切る。
- detached worktree は再利用しない。必要なら先に名前付き branch へ退避する。
- 同じファイルだけを理由に`red`へ分類しない。validなpreflightの`changes`またはfallback時のGit diffと、予定するsymbol・責務・仕様を比較する。
- live taskに対応しないworktreeの変更も、競合候補から除外しない。
- `red` 判定なら、勝手に作業を始めず競合点を明示して確認する。
- `yellow` 判定なら、別worktreeを使い、各sessionの編集領域と統合順序を先に言語化してから開始する。
- 同一ファイルを並行編集したbranchは、先に一方を統合し、他方を最新の基準branchへ追従させて差分確認と関連テストを行う。
- current task の編集symbol・責務が曖昧なら、独立性を確認できるまで`red`としてscopeを明確にする。

# Queueing Policy

**REQUIRED POLICY:** global `AGENTS.md`の「別セッションへの後続依頼」を正本として従う。このskillではユーザーへの事前説明、非割り込み、キュー受付と着手の区別を再定義しない。

- 送信前に`read_thread`でactive turn summaryを記録し、別に`wait_threads`の`timeoutMs: 0`でevent cursorを取得する。
- task IDと`hostId`を`send_message_to_thread`へ渡し、その結果で対象taskとキュー受付を確認する。
- 送信直後は`read_thread`で同じactive turnが継続していることを確認する。後続着手は保存したevent cursorを`wait_threads.afterCursor`へ渡して待ち、`read_thread`で新しいturnとassistant出力を確認する。
- 正確な依頼先、live状態、非割り込みのキュー動作、受付結果のいずれかを確認できない場合は送信しない。

# Stop And Ask

- 同じ編集領域、責務、またはfeatureを別sessionが触っており、既存所有セッションへ後続キューを積むのが適切か判断できない
- Codex appのtask情報を取得できず、ID、`hostId`、live状態を確認できない
- どの branch を基準に切るべきかで結論が変わる
- dirty な detached worktree を処理しないと安全な切り出しができない
- 既存の未 commit 変更を移動、stash、cleanup しないと進めない

# Reporting Format

結果は短く、次の順で返す。

1. 今の自分の作業とぶつかるか
2. Git状態の取得元（preflightまたはfallback）と完全性
3. live `status`を確認したrepo-scoped task / worktreeと、identity未確認の`unscoped` task
4. 重複または競合の根拠
5. 推奨する作業領域
6. 後続キューへ積んだ場合は、対象セッション名・ID・受付状態
7. 実際に作成した path / branch があればその場所

# Notes

- taskのactive / idleは必ず`list_threads`のlive `status`で判断する。
- repository identityはtaskの所属確認にだけ使い、Git状態の証拠として扱わない。
- task確認より前に取得したGit snapshotからgreen / yellowを判定しない。
- このguardは時点をそろえたsnapshot確認でありlockではない。開始可能と判断した作業領域は直ちに使い、新しいtask / worktree activityを観測した場合や開始が遅れて鮮度を保証できない場合は編集前にguardをやり直す。
- taskのscopeは`read_thread`と、validなpreflightの`changes`またはfallback時の対応worktree Git diffの両方で裏取りする。
- `main の作業を確認して`のような依頼では、task指定がなくてもlive task inventoryと、validなpreflightのbaseline / `changes`、またはfallback時のcurrent `main` commit / diffを確認する。
