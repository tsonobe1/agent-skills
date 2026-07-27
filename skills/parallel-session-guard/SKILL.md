---
name: parallel-session-guard
description: Use when work may overlap another Codex session, branch, worktree, or changed file; when active session ownership must be checked; or when follow-up work may need to be queued to an existing owning session.
---

# Objective

複数の Codex セッションを同時に進める前に、最近の作業と現在の Git 状態を照合し、競合しにくい作業領域を決める。

**Core principle:** 同じbranch、編集領域、または設計責任の所有者を増やさない。ファイルの重複だけでは競合と断定せず、変更するsymbol・責務・仕様を比較する。所有セッションが実行中なら、そのturnを中断しない。後続依頼が現在のvisible scope内ならユーザーへ説明してからキューへ積み、scopeを拡張するならidleになるまで待つかユーザーへ報告する。

このskillはCodex appのtask inventory toolsを前提とするCodex専用skillである。Claude / Grok runtimeへ同期したり、それらのruntimeでGit証拠だけに縮退して実行したりしない。

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
- Codex appの`read_thread`: 候補taskの現在scope、最新turn、scope anchor chain、user / assistant message identity
- Gitのrepository identity: repo rootとtask `cwd`が同じrepositoryに属するかの確認だけ
- Ugen preflightが存在しないcheckoutでのみ、Gitのworktree、branch、dirty state、diff

`~/.codex/sessions`などの内部ログや更新時刻から、taskのactive状態や所有者を推測しない。Codex appのtask情報を確認できない場合は、正確な依頼先を特定できないものとして送信を止め、ユーザーへ報告する。

repository identityの確認では、repo rootと各task `cwd`のcanonical common Git directoryだけを比較する。これはtaskのrepo所属を絞るための確認であり、branch、worktree一覧、HEAD、dirty state、diffを収集しない。結果は`repo-scoped`、`outside-repo`、`unscoped`へ分類する。

- common Git directoryが対象repoと一致するtaskは`repo-scoped`
- canonical cwdが対象repo rootと同一またはpath separator境界付き祖先なら、common Git directoryが別repositoryでも対象repoへ移動できるため`unscoped`
- canonical common Git directoryの解決に成功し、対象repoと不一致で、canonical cwdが対象repo rootのpath separator境界付き祖先でもないtaskは`outside-repo`
- canonical cwdの存在・access確認に成功し、安定化したlocaleで明確な`not a git repository`が返り、cwdからfilesystem rootまで`.git` markerがなく、対象repo rootと同一でもpath separator境界付き祖先でもないtaskは`outside-repo`
- non-Gitのcanonical cwdが対象repo rootと同一またはpath separator境界付き祖先なら、taskが対象repoへ移動できるため`unscoped`
- permission、I/O、cwd消失、canonicalize、timeout、tool、dubious ownership、壊れた`.git`、未知の失敗は`unscoped`

`outside-repo`はrepo inventoryから除外するが、task ID、cwd、分類理由、解決済みならcanonical common Git directoryを記録する。`unscoped`はfail closed対象とする。

```sh
git -C <cwd> rev-parse --path-format=absolute --git-common-dir
```

Git snapshot取得後にtask `cwd`をworktreeへ対応付けるときは、task `cwd`と各worktree pathをcanonical absolute pathへ正規化し、path separator境界を含む包含判定を行う。`cwd`と同一、または`cwd`を含む候補のうち最長pathを選ぶ。候補なし、canonicalize失敗、同じ長さの候補が複数ある場合はtaskを`unscoped`としてfail closedにする。文字列prefixだけで`/repo`を`/repo-other`へ対応付けない。

task snapshotは、`list_threads`のtask ID、`hostId`、canonical repository identity、`cwd`、live status、`read_thread(turnLimit: 1, includeOutputs: false)`の最新turnと、同じtaskをcursorで過去へ辿って復元したcurrent scopeから作る。`y`、`continue`、短い承認、代名詞や参照だけのuser messageを単独のscope anchorにしない。最新turnから、現在の作業を定義する最後のsubstantive user request、それ以後のuser修正、短い返答が直接参照する完了済みassistant提案まで必要なpageだけを辿り、予定file、symbol、責務、仕様、未着手項目をscope anchor chainとして復元する。anchor chainが完成する前にcursor pageを取得できない、参照先が一意でない、または必要なhistoryがpartial / truncatedならfail closedにする。

scope fingerprintには、最新turnのID、status、`startedAt`、`completedAt`、error、scope-defining user itemのIDとexact UTF-8 contentのSHA-256、直接参照された完了済みassistant itemのIDとcontent SHA-256、normalized reconstructed scopeのSHA-256だけを含める。reasoning、tool activity、active turnで増加中のassistant outputは作業進捗で変化するためfingerprintへ含めない。caller taskを一意に特定できない場合もfail closedにする。

task inventoryのcoverageは、`exhaustive`または`bounded latest N`として記録する。`list_threads`が明示的にexhaustedを返す、または返却件数が指定limit未満なら`exhaustive`とする。返却件数がsupported maximum limitと同数で次page cursorがない場合は、その返却集合を`bounded latest N`として使う。cursorがある場合は同じsnapshot系列のpageをexhaustedまで取得し、重複・欠落・source unavailableがないことを検証する。

`bounded latest N`はtask履歴全体のcomplete inventoryではないが、それだけを理由に停止しない。initial、A、Bを同じlimitで取得し、全返却taskのtask集合・statusと、repo-scoped taskだけのscope fingerprintの一致を要求する。N件より古いtaskは未確認と報告し、「全task確認済み」または「task inventory complete」と表現しない。Git側はcoverageにかかわらず、全登録worktreeを含むcomplete snapshotを必須とする。

# Ugen Preflight

repo rootを解決し、正確なpathの存在確認が成功して`scripts/worktrees/preflight.mjs`が存在する場合は、repo-scoped taskのfinal initial read pass直後に、個別Git状態確認より先に、repo rootから引数なしで1回だけ実行する。final initial read passとpreflightの間に別のtool call、調査、またはユーザー判断を挟まない。実行前にmonotonic clockで120秒後のdeadlineを記録し、独立してterminateできるjobとして開始する。deadlineまでpollし、未完了なら実行toolのterminate機能でjobのprocess treeを強制終了して、停止済みを確認する。この制御を保証できない場合は実行せずfail closedとする。

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

fallbackのbaselineは、明示されたimmutable commit、またはfreshnessを確認したremote default branchのどちらかだけを使う。明示commitはcommitに解決して`pinned: true`として固定する。remote由来ではrepo instructionsで指定されたremote、または一意に特定できるremoteに対し、bounded hard deadlineでauthoritative `HEAD`のsymrefを問い合わせ、そのdefault branchをfetchする。実行を安全にterminateできない、timeout、認証、network、非zero終了、symref不正、fetch後のref / SHA不一致ならcached remote-tracking refへ戻らずfail closedにする。fetch成功後のrefと固定したSHAを`refreshed: true`としてbaselineにする。

`origin/main`、`main`、`trunk`、current branch、最初に見つかったremoteを推測で選ばない。baseline refまたはSHAが解決不能、複数候補、dangling、unbornならGit証拠を不完全としてfail closedにする。

全worktreeでHEAD SHAを固定し、named / detached、clean / dirty、live taskの有無にかかわらず、committed pathsを同じ比較で収集する。

```sh
git diff --name-status -z --find-renames <baseline-sha>...<worktree-head-sha>
```

NUL区切りのname-status recordをparseし、通常の変更は1個のpath、rename / copyはsourceとdestinationの両pathをcommitted pathsへ含める。未知status、必要pathの欠落、malformedまたはtruncated recordが1件でもあればsnapshotを不完全とする。

merge base、worktree HEAD、diff、statusのいずれかを解決できないworktreeが1つでもあればsnapshot全体を不完全とする。detached worktreeもcommitted pathsとdirty pathsを収集対象に含めるが、作業領域として再利用しない。

fallbackでは収集前のworktree inventory Aに、canonical path、HEAD SHA、branch、detached、locked、prunableと、parsed statusのstaged / unstaged / untracked path分類を保存する。baseline、全status、全committed diffの収集直後にworktree一覧と全statusをinventory Bとして再取得し、worktree集合、各tuple、各status path分類がAに完全一致し、各diffがAで固定したHEAD SHAを使ったことを要求する。add / remove、HEAD移動、tuple差分、dirty path差分、parseまたは取得失敗があればsnapshotを破棄し、新しいGit状態を古いtask snapshotへ追加せずguard全体を最初からやり直す。このretryはtask inventory変化と共有して全体で1回までとし、再び変化した場合は`Git inventory unstable`として停止する。

# Workflow

1. repo rootとrepository identityだけを解決する。この時点ではbranch、worktree一覧、HEAD、dirty state、diffを個別Git commandで収集しない。
2. 正確なscript path lookupの結果を、存在、`ENOENT`、その他のinspection errorに分類する。この時点ではpreflightもfallback Git状態収集もまだ実行しない。
3. `list_threads`をqueryなし・supported maximum limitで呼び、task inventory coverageを`exhaustive`または`bounded latest N`として記録する。返却件数がlimitと同数でnext page cursorがなくても、`bounded latest N`として続行する。返却された各task `cwd`を`repo-scoped`、`outside-repo`、`unscoped`へ分類する。tool responseがpartial、明示的なtruncation error、またはsource unavailableを示す場合は停止する。
4. repo-scoped候補を`read_thread(turnLimit: 1, includeOutputs: false)`で確認し、必要な候補だけ同じtaskのcursorで過去へ辿ってscope anchor chainを復元する。caller task、ID、`hostId`、live `status`、現在scope、未着手項目、最新turn snapshotを保存する。このpassでcaller taskを一意に特定でき、返却されたrepo-scoped候補集合、各snapshot、各anchor chainが構造的に完全であることを確認する。partial、矛盾、scope復元不能、またはcaller不明ならfinal initial read passへ進まず停止する。
5. 同じ候補を同じ引数とscope復元規則で再取得してfinal initial read passを作る。最初のpassとtask ID、`hostId`、canonical identity、`cwd`、live status、scope anchor chain、scope fingerprintが一致し、全callが完全なら、最後の`read_thread`の次のtool callとしてGit snapshot取得を開始する。差分または失敗があればGit snapshotを取らず、Workflow 9と同じ全体retry制限でguardを最初からやり直す。
6. scriptが存在する場合は120秒のhard deadlineでUgen preflightを1回実行して契約を検証する。invalidまたはtimeoutならGit証拠を不完全として開始・競合判定をblockする。
7. path lookupが`ENOENT`を返した場合だけ、fallback Git snapshotを集める。
   - `git worktree list --porcelain -z`
   - 各worktreeについて `git -C <worktree> status --porcelain=v1 -z --untracked-files=all --no-renames`
   - 収集直後に`git worktree list --porcelain -z`と全worktreeのstatusを再取得し、inventory A / Bを比較する
8. fallbackではworktree inventory AもNUL区切りのporcelain fieldとしてparseする。次にfreshまたはpinnedなbaseline ref / SHAと全worktreeのHEAD SHAを固定し、各HEADのcommitted pathsを収集する。statusはNUL区切りのporcelain v1 recordとしてparseし、XY列からstaged / unstaged / untracked pathを分類する。収集直後に同じparseでworktree一覧と全statusをinventory Bとして取得し、A / Bのworktree集合、各tuple、各status path分類、およびdiffに使った固定HEAD SHAの一致を検証する。malformed、truncated、unknown、directory集約のrecord、またはinventory差分が1件でもあればsnapshotを破棄し、共有された全体retry上限に従う。
9. preflightまたはfallback Git snapshot後、次の順でpost-preflight snapshotを取得する。
   1. initialと同じlimitの`list_threads`とrepository identityの対応付けからinventory Aを作り、coverageを記録する。
   2. Aの全repo-scoped候補を同じ引数とscope復元規則の`read_thread`で取得してscope Aを作る。
   3. もう一度initialと同じlimitの`list_threads`とrepository identityの対応付けからinventory Bを作り、coverageを記録する。
   4. Bの全repo-scoped候補を同じ引数とscope復元規則の`read_thread`で取得してscope Bを作る。
   全taskを再分類し、final initial、A、Bで、全返却taskのcoverage、task ID、`hostId`、identity classification、canonical identity、`cwd`、live statusが一致することを要求する。scope anchor chainとscope fingerprintはrepo-scoped taskだけで一致を要求する。`bounded latest N`の境界変化や`outside-repo` / `repo-scoped` / `unscoped`間の変化もtask集合の差分として扱う。差分があれば新しいtaskを古いGit snapshotへ追加せず、開始判断をblockしてguard全体を最初からやり直す。taskまたはGit inventory変化による全体retryは共有して1回までとし、再び変化した場合はinventory unstableとして停止する。
10. taskの`cwd`をcanonical absolute worktree pathへ境界付き最長一致で対応付ける。対応不能または同長の複数候補は`unscoped`とする。validなpreflightでは`changes`をGit差分証拠、`fileOverlaps`を既存worktree同士の重複候補抽出に使うが、それだけで競合と断定しない。
11. Git証拠が不完全、task sourceがpartial / error、callerを一意に特定できない、または`unscoped` taskが残る場合は、契約違反、repo-scoped task inventory、`unscoped` taskを分けて報告し停止する。`bounded latest N`だけを停止理由にはしないが、coverageと未確認範囲を明記する。
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
| `red`かつ既存所有セッションが続ける | visible scope内なら事前説明して後続キューへ積む。scope拡張なら送信しない |
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

- 送信前に`read_thread(turnLimit: 1, includeOutputs: false)`でactive turn snapshotを保存し、同じscope復元規則で対象taskのcurrent scopeを確認する。正確な依頼先、live状態、current scope、非割り込みのキュー動作を確認できない場合は送信しない。
- 対象taskが実行中なら、follow-upの予定file、symbol、責務、仕様が、snapshotで確認できる対象taskの現在scopeにすべて含まれる場合だけ送信する。この場合は既に見えているscopeがownershipを保持する。follow-upが現在scopeを拡張する場合、current toolsではqueued scopeを後続guardが再取得できるdurable reservationとして保存できないため送信せず、対象taskがidleになるまで待つかユーザーへ報告する。
- task IDと`hostId`を`send_message_to_thread`へ渡して1回だけ送信し、結果から対象taskとacceptance / dispositionを記録する。
- `send_message_to_thread`がsuccess、timeout、transport error、不明な結果のいずれでも再送しない。送信済みの可能性を保持したまま、取得可能なら同じ引数の`read_thread`を1回だけ取得し、送信前snapshotと比較する。
- send resultがacceptanceを確認し、旧turnが継続中または一致する新turnがまだなければ`accepted / queued`と報告し、着手済みと呼ばない。これは受付状態だけを表し、新しいownership予約とは扱わない。対象taskの送信前scopeに含まれないfollow-upをこの状態へ進めてはならない。
- send resultがacceptanceを確認し、送信前と異なるturn IDと、送信したfollow-upに一致する新turnを`read_thread`で確認できた場合は`accepted / started`と報告する。旧turnの自然終了後に新turnが始まる遷移をinterrupt扱いしない。
- send resultがacceptanceを確認したが、送信後snapshotを取得できない場合は`accepted / new turn unconfirmed`として停止する。再送せず、ユーザーへ確認を求める。
- send resultがtimeout、transport error、不明な結果、またはacceptance未確認の場合は、送信後snapshotの取得成否や一致するnew turnの有無にかかわらず`ambiguous`として停止する。acceptance、target、turn snapshot、new turnの対応がpartial、矛盾、または一致不能な場合も同じとする。送信済みの可能性があるため再送せず、観測できた送信後snapshotと確認不能な点をユーザーへ報告する。

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
3. live `status`を確認したrepo-scoped task / worktree、別Git repositoryまたは明確なnon-Git cwdの`outside-repo` task、identity未確認の`unscoped` task
   - task inventory coverageが`bounded latest N`なら、Nと「それより古いtaskは未確認」を明記する
4. 重複または競合の根拠
5. 推奨する作業領域
6. 後続キューへ積んだ場合は、対象セッション名・ID・受付状態
7. 実際に作成した path / branch があればその場所

# Notes

- taskのactive / idleは必ず`list_threads`のlive `status`で判断する。
- `bounded latest N`をtask履歴全体のcomplete inventoryと呼ばない。競合判定は「最新N件のtaskと全worktreeのGit状態に基づく」と表現する。
- repository identityはtaskの所属確認にだけ使い、Git状態の証拠として扱わない。
- task確認より前に取得したGit snapshotからgreen / yellowを判定しない。
- このguardは時点をそろえたsnapshot確認でありlockではない。開始可能と判断した作業領域は直ちに使い、新しいtask / worktree activityを観測した場合や開始が遅れて鮮度を保証できない場合は編集前にguardをやり直す。
- taskのscopeは`read_thread`と、validなpreflightの`changes`またはfallback時の対応worktree Git diffの両方で裏取りする。
- `main の作業を確認して`のような依頼では、task指定がなくてもlive task inventoryと、validなpreflightのbaseline / `changes`、またはfallback時のcurrent `main` commit / diffを確認する。
