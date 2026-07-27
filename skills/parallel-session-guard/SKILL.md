---
name: parallel-session-guard
description: Use when work may overlap another Codex session, branch, worktree, or changed file; when active session ownership must be checked; or when follow-up work may need to be queued to an existing owning session.
---

# Objective

複数の Codex セッションを同時に進める前に、最近の作業と現在の Git 状態を照合し、競合しにくい作業領域を決める。

**Core principle:** 同じbranch、編集領域、または設計責任の所有者を増やさない。ファイルの重複だけでは競合と断定せず、変更するsymbol・責務・仕様を比較する。所有セッションのturnを中断しない。後続依頼は対象taskの現在のvisible scope内に完全に含まれる場合だけ、ユーザーへ説明してからキューへ積む。scopeを拡張する依頼は対象taskのidle / runningにかかわらず送信しない。

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
- Codex appの`read_thread`: 返却された全Codex taskの現在scope、最新turn、scope anchor chain、user / assistant message identity
- Gitのrepository identity: repo rootとtask `cwd`が同じrepositoryに属する可能性を絞るための一次証拠
- Ugen preflightが存在しないcheckoutでのみ、Gitのworktree、branch、dirty state、diff

`~/.codex/sessions`などの内部ログや更新時刻から、taskのactive状態や所有者を推測しない。Codex appのtask情報を確認できない場合は、正確な依頼先を特定できないものとして送信を止め、ユーザーへ報告する。

repository identityの確認では、repo rootと各task `cwd`のcanonical common Git directoryだけを比較する。これはtaskの通常の所属先を絞る一次分類であり、別repositoryからabsolute path、`git -C`、toolの`workdir`などで対象repoを変更しないことの証拠ではない。この段階ではbranch、worktree一覧、HEAD、dirty state、diffを収集せず、結果を`repo-candidate`、`outside-candidate`、`unscoped`へ分類する。

target repositoryのlocal identityとは別に、repository-scoped toolのselector比較用としてauthoritative hosted identityを解決する。repo instructionsがremoteを指定していればそのremote、指定がなければtarget common Git directoryに属する全worktreeで一意なremote URLだけを使う。HTTPS、`ssh://`、scp-like SSH URLをcredentialや末尾の`.git`に依存しないcanonical host / owner / repositoryへ正規化し、local common Git directoryとbindingする。basename、remote名、現在branch、最初に見つかったremoteから推測しない。remoteなし、複数の異なるhosted identity、URL parse不能、bindingの矛盾またはsnapshot間の変化がある場合、hosted selectorを別repoと判定せず`unscoped`としてfail closedにする。local path routingはlocal identity、structured repository selectorはこのbinding済みhosted identityと比較する。

- common Git directoryが対象repoと一致するtaskは`repo-candidate`
- canonical cwdが対象repo rootと同一、path separator境界付き祖先、またはpath separator境界付き子孫なら、common Git directoryが別repositoryでも対象repoへ移動できるため`unscoped`
- canonical common Git directoryの解決に成功し、対象repoと不一致で、canonical cwdと対象repo rootがpath separator境界付き包含のどちらの向きにも該当しないtaskは`outside-candidate`
- canonical cwdの存在・access確認に成功し、安定化したlocaleで明確な`not a git repository`が返り、cwdからfilesystem rootまで`.git` markerがなく、canonical cwdと対象repo rootがpath separator境界付き包含のどちらの向きにも該当しないtaskは`outside-candidate`
- non-Gitのcanonical cwdが対象repo rootと同一、path separator境界付き祖先、またはpath separator境界付き子孫なら、taskが対象repoへ移動できるため`unscoped`
- permission、I/O、cwd消失、canonicalize、timeout、tool、dubious ownership、壊れた`.git`、未知の失敗は`unscoped`

一次分類後、返却された全Codex taskのscope anchor chainを復元する。scopeが対象repoのcanonical root、その配下のpath、repository URL / identity、予定file、symbol、責務、仕様、または解決済みtool routingのいずれかを対象にしていれば、cwdにかかわらず`target-scoped`とする。`outside-candidate`を`outside-repo`として除外できるのは、scope復元とtool routingの検査が完全で、対象repoへの関与がないと確認できた場合だけとする。cross-repoの`target-scoped` taskはcwdを対象worktreeへ対応付けず、scopeを全worktreeと新しい予定scopeに直接比較する。`unscoped`はfail closed対象とする。

```sh
git -C <cwd> rev-parse --path-format=absolute --git-common-dir
```

Git snapshot取得後にsame-repoの`target-scoped` task `cwd`をworktreeへ対応付けるときは、task `cwd`と各worktree pathをcanonical absolute pathへ正規化し、path separator境界を含む包含判定を行う。`cwd`と同一、または`cwd`を含む候補のうち最長pathを選ぶ。候補なし、canonicalize失敗、同じ長さの候補が複数ある場合はtaskを`unscoped`としてfail closedにする。文字列prefixだけで`/repo`を`/repo-other`へ対応付けない。

task snapshotは、`list_threads`のtask ID、`hostId`、canonical repository identity、`cwd`、live status、`read_thread(turnLimit: 1, includeOutputs: false)`の最新turnと、同じtaskをcursorで過去へ辿って復元したcurrent scopeから作る。`y`、`continue`、短い承認、代名詞や参照だけのuser messageを単独のscope anchorにしない。最新turnから、現在の作業を定義する最後のsubstantive user request、それ以後のuser修正、短い返答が直接参照する完了済みassistant提案、file、symbol、責務、仕様の追加または変更を明示したstableなassistant message item、およびstableなtool invocation itemまで必要なpageだけを辿り、予定scopeと未着手項目を復元する。

各tool invocationは、scopeへ入れる前に次の`tool invocation evidence`へ正規化する。

- **routing**: 明示されたtool `cwd` / `workdir`をtaskのcanonical cwdから解決し、なければtask cwdをeffective baseとする。tool schemaのpath field、patch header、literalなfile operand、shellの順序付きliteral `cd`、`git -C`の実operand、およびshell grammar上の全redirect target（fd prefix付きのinput / output / append / read-write / clobberを含む）を抽出し、relative pathをそのoperand評価時点のeffective baseから解決する。output / append / read-write redirectはmutation、input redirectはread routingとしてeffectへ渡す。tool schemaのrepository selector（`owner` + `repo`、`repo_full_name`、`repository_full_name`、repository URL / identity、およびschemaが同義と定義するfield）は実値をcanonical host / owner / repository identityへ正規化し、target local identityへbinding済みのauthoritative hosted identityと一致すればcwdに関係なくtarget-relevantとする。hostを省略するselectorはtool schemaが一意なhostを保証する場合だけ補完する。target hosted identityのbinding、alias、default、欠落、矛盾、変数展開、process substitution、動的redirectまたはfd semanticsを一意に解決できなければ`unscoped`とする。`.` / `..`とsymlinkを解決し、存在しない末尾は最長の存在ancestorをcanonicalizeしてからpath separator境界を保って正規化する。各解決済みpathは、directoryなら自身、fileならparent、存在しない末尾なら最長の存在ancestorを起点にrepository-identity-only probeを行う。canonical common Git directoryがtarget local identityと一致するか、Git snapshot取得後の全target worktree canonical rootのいずれかとpath separator境界付きで一致する場合は、単一target root外のlinked worktreeでもtarget-relevantとする。probeが成功して別common Git directoryを返し、target worktree rootsとの境界付き包含もない場合はtarget-irrelevantとする。canonical pathの存在・access確認に成功し、安定化したlocaleで明確な`not a git repository`が返り、ancestorに`.git` markerがなく、target worktree rootsとの境界付き包含もない場合もtarget-irrelevantとする。permission、I/O、timeout、parse、dubious ownership、壊れた`.git`、non-Git判定不能、target worktree集合との矛盾、またはidentity / worktree集合のsnapshot間変化は`unscoped`とする。文字列prefix、basename、target root外という理由だけで別repoと判定しない。`cwd` / `workdir` key、repository selector key、redirect token、または`git -C` tokenの存在だけではtarget-relevantにしない。opaque executable、local script、package / task runnerは、schemaまたはinspectionしたsource / manifest / resolved command chainがpath confinementを保証する場合だけ全operandを別repositoryと確定できる。動的download、生成path、変数、`eval`、unknown binary、partial inspection、またはrouting semanticsを完全に確認できない実行は`unscoped`としてfail closedにする。
- **provenance**: defaultは`task-owned`とする。guard開始時、最初のtool callより前にcaller item boundary、versioned run ID、空ledgerを固定する。各許可済みevidence collection invocationは発行直前に、run ID、caller task ID / `hostId`、start boundary、単調増加ordinal、purpose、tool名、canonical arguments SHA-256、expected routing / effect / lifecycleからdeterministic `callIdentity`を固定してledgerへ追加する。現在のguard runがWorkflow 1–9で発行したinvocationは、観測後のeffect / lifecycle、run boundaryもledgerへ追記し、各read passで一意に対応したexact item IDを`guard-owned`とする。対象はrepo root / identity、script path lookup、task inventory / scope read、preflight、fallback snapshot、post-read identity probeに限定する。mutationを許すのは、authoritative baselineをfreshにするためWorkflowで明示したbounded ref refreshだけとし、terminal完了、固定したref / SHA、観測したeffectが契約どおりであることをGit snapshotで検証する。その他のmutation、unfinished / unknown lifecycle、想定外effectはfail closedにする。同じcommand文字列という理由だけで除外しない。対応が欠落、重複、partial、または一意でなければfail closedにする。`guard-owned` itemはscope anchor / fingerprintへ入れず、Git / task / identity evidenceとして別管理する。

  完了・停止を問わず各guard runの結果を返す直前に、stableなassistant message itemとして`guard provenance record`を1個残す。recordは`payload`と`recordHash`をsibling fieldとして持つ。`payload`はschema version、run ID、caller task ID / `hostId`、開始 / 終了item boundary、target local / hosted repository identity、terminal result、`complete`を持ち、ledger各項目を発行順の`callIdentity`、exact item IDまたは`null`、purpose、tool名、canonical argumentsのSHA-256、解決済みまたはexpected routing / effect / lifecycleで表す。history readのpartial / unavailable / truncatedによりitem対応前に停止する場合は`complete: false`とし、発行済みattemptを`itemId: null`のまま欠落させず記録する。`recordHash`は自身を含めず`payload`だけをRFC 8785 JSON Canonicalization SchemeでserializeしたUTF-8 bytes（BOMなし、前後whitespace / trailing newlineなし）のSHA-256 lowercase hexadecimalとする。duplicate key、non-finite number、RFC 8785で表現不能な値はrecord作成・検証をfail closedにする。

  後続runは必要なfull historyをcursorで取得し、`payload`から再計算した`recordHash`とrun / caller / boundaryを先に検証する。`itemId: null`のentryは、完全なboundary区間内でordinal順、tool名、canonical arguments hash、purposeと観測lifecycleが一意に一致するstable invocation itemが1個だけならitem IDを補完してhistorical `guard-owned`へ昇格できる。完全な区間に対応itemが存在しなければ`no-item`として、除外対象のtool itemが存在しないことを記録する。重複、欠落しているはずのない追加item、順序不一致、partial / redacted / truncated history、hash / boundary / lifecycle不一致では補完せず`unscoped`としてfail closedにする。prose、command文字列の類似、record単独では継承しない。検証済みhistorical `guard-owned` itemだけをscope anchor / fingerprintへ入れない。
- **effect / lifecycle**: tool schemaとoperation全体がlocal filesystem、Git refs / worktrees、remote repository、issue / PR / review / project、message / queue、その他durable external stateのcreate / update / delete / send / merge / dispatch / uploadを行わず、子孫・background / scheduled actionも残さないと保証できる場合だけ`read-only`とし、それ以外は`mutating-or-unknown`とする。`mutating-or-unknown`なtarget-relevant task-owned invocationがpending / running / terminal不明、または子孫・background actionの終了を確認できない場合はtaskを`unscoped`として開始をblockする。terminal化を確認した後に新しいGit snapshotでguard全体をやり直す。当該invocationのlifecycle metadataが取得不能、redacted、partial、truncatedならunfinishedとしてfail closedにする。tool output / result本文はscope evidenceにしない。

`task-owned`かつtarget-relevantなtool invocation evidenceはscope anchor chainへ含める。message / tool anchorは古いturnから新しいturn、同一turn内のitem順で並べる。anchor chainが完成する前にcursor pageを取得できない、参照先が一意でない、または必要なhistoryがpartial / truncatedならfail closedにする。

scope fingerprintには、最新turnのID、status、`startedAt`、`completedAt`、errorと、決定的な順序のscope anchor chainだけを含める。message anchorはturn ID、item ID、role、exact UTF-8 contentのSHA-256で表す。target-relevant tool anchorはturn ID、item ID、tool名、canonical argumentsのSHA-256、解決済みtarget path / identity、effect、lifecycle classで表し、secretを平文へ残さない。canonical argumentsはobject keyをsortし、array順とscalar値を保つ。tool output / result本文はfingerprintへ含めない。AIが再構成したsemantic scopeやその要約、reasoning、生成途中のoutput block、target-relevantでないtool activity、exactに対応した`guard-owned` itemはfingerprintへ含めない。stableなassistant scope拡張と`task-owned` target-relevant tool evidenceは必ずanchorとfingerprintへ含める。caller taskを一意に特定できない場合はfail closedにする。

task inventoryのcoverageは、`exhaustive`または`bounded latest N`として記録する。`list_threads`が明示的にexhaustedを返す、または返却件数が指定limit未満なら`exhaustive`とする。返却件数がsupported maximum limitと同数で次page cursorがない場合は、その返却集合を`bounded latest N`として使う。cursorがある場合は同じsnapshot系列のpageをexhaustedまで取得し、重複・欠落・source unavailableがないことを検証する。

`bounded latest N`はtask履歴全体のcomplete inventoryではない。initial、A、Bを同じlimitで取得し、返却されたN件すべてのtask集合、status、scope fingerprintの一致を要求する。N件より古いtaskのstatus / scope fingerprintは未確認であり、clean worktreeは未着手scope ownershipがない証拠にならない。Git側はcoverageにかかわらず、全登録worktreeを含むcomplete snapshotを必須とする。

bounded coverageでもGit / task snapshotの収集と既知のred判定までは続けるが、未知の古いownershipが残るため`green`または「安全」と判定しない。結果は`coverage-limited`として、N、未確認範囲、予定scope、残るriskをユーザーへ示す。提示時にはfingerprint文字列を含まないdeterministicな`riskMessageBody`を先に固定する。bodyはcoverage種別 / N、target local / hosted repository identity、返却順のtask ID / `hostId` / status / scope fingerprint、oldest visible task boundary identity、予定scope anchor chain、未確認範囲の説明というstable risk factsだけを固定順でrenderする。guard run ID、guard開始 / 終了boundary、invocation item ID / ordinal、`recordHash`、実行timestampなどrun固有のprovenance値をbodyへ含めず、provenance表示は別の`guard provenance record` itemに限定する。そのexact UTF-8 body SHA-256を同じstable risk factsとともにRFC 8785 JCS payloadへ入れ、run固有のprovenance fieldはrisk payloadへ入れない。このpayloadのSHA-256 lowercase hexadecimalを`coverage risk fingerprint`として承認対象にする。表示messageはexact `riskMessageBody`の直後へ固定形式の`\n\ncoverage risk fingerprint: <fingerprint>` suffixだけを付ける。suffixを`riskMessageBody`またはそのcontent hashへ含めない。

coverage risk専用projectionではcallerの提示中turnだけ、volatileなstatus / `startedAt` / `completedAt` / errorを含むturn lifecycle envelopeを使わず、turn ID、提示直前のimmutable item boundary、そこまでの正規化済みscope anchor chain SHA-256へ置換する。提示するrisk messageは発行前に`riskMessageBody` hash、固定suffix形式、期待順を承認対象へ固定し、item IDは発行後の履歴照合にだけ使う。直後のturnがexact risk fingerprintへの明示的なapprovalだけの場合、approval message直後かつ再guard最初のtool call前にrun boundaryを固定する。再guardでは、提示turnがterminal successであること、固定boundary後に承認済みbody hash / suffixと順序へexactに対応するrisk message / provenance record以外のscope追加、message anchor、task-owned target-relevant tool invocationがないことをfull historyで検証し、固定boundaryまで同じ専用projectionを再構成する。prior runのprovenance recordとcurrent runのledger / recordは、それぞれのrun ID、boundary、item対応、`recordHash`を使ってrisk fingerprint equalityとは別に完全検証する。そのうえでapproval turnのlifecycle envelope、承認message、exactに対応した再guardの`guard-owned` itemだけをcoverage risk比較から除外する。partial history、terminal error、provenance検証失敗、追加item、scope追加、別のsubstantive request、またはledger外のtask-owned target tool invocationが1件でもあれば古い承認を使わず再承認を要求する。各guard run内の生scope fingerprint比較は、exact guard-owned item以外を正規化せず、turn lifecycle metadataを含めて従来どおり完全一致を要求する。ユーザーがそのfingerprintで特定されたriskを受け入れて進行を指示した場合だけ、同じNでguard全体を再実行する。approval-only projectionを適用した再実行後のrisk fingerprintが完全一致し、安定した最新snapshotで既知のyellow / redがない場合だけ開始できる。1項目でも変われば古い承認を失効させ、変更後のriskとfingerprintを提示して再承認を求める。この場合も判定名と報告は`coverage-limited override`であり、task inventory completeまたはgreenとは表現しない。

# Ugen Preflight

repo rootを解決し、正確なpathの存在確認が成功して`scripts/worktrees/preflight.mjs`が存在する場合は、全Codex taskのfinal initial read pass直後に、個別Git状態確認より先に、repo rootから引数なしで1回だけ実行する。final initial read passとpreflightの間に別のtool call、調査、またはユーザー判断を挟まない。実行前にmonotonic clockで120秒後のdeadlineを記録し、独立してterminateできるjobとして開始する。deadlineまでpollし、未完了なら実行toolのterminate機能でjobのprocess treeを強制終了して、停止済みを確認する。この制御を保証できない場合は実行せずfail closedとする。

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

1. 最初のtool callより前にcaller item boundary、versioned run ID、空のguard-owned ledgerを固定する。各tool callの発行直前にdeterministic `callIdentity` entryを追加する。repo root、local repository identity、authoritative hosted identity bindingだけを解決し、発行したinvocationをpurpose付きでledgerへ追記する。repo instructions指定または一意なremote URL以外からhosted identityを推測しない。この時点ではbranch、worktree一覧、HEAD、dirty state、diffを個別Git commandで収集しない。
2. 正確なscript path lookupのexact invocationをledgerへ追加し、結果を存在、`ENOENT`、その他のinspection errorに分類する。この時点ではpreflightもfallback Git状態収集もまだ実行しない。
3. `list_threads`をqueryなし・supported maximum limitで呼び、task inventory coverageを`exhaustive`または`bounded latest N`として記録する。返却件数がlimitと同数でnext page cursorがなくても、既知の競合調査は続行する。返却された各Codex task `cwd`を`repo-candidate`、`outside-candidate`、`unscoped`へ一次分類する。tool responseがpartial、明示的なtruncation error、またはsource unavailableを示す場合は停止する。
4. 返却された全Codex taskを`read_thread(turnLimit: 1, includeOutputs: false)`で確認し、必要なtaskだけ同じtaskのcursorで過去へ辿ってscope anchor chainを復元する。cwd一次分類とscopeの両方から`target-scoped`、`outside-repo`、`unscoped`を確定し、caller task、ID、`hostId`、live `status`、現在scope、未着手項目、最新turn snapshotを保存する。このpassでcaller taskを一意に特定でき、全Codex taskの各snapshotと各anchor chainが構造的に完全であることを確認する。partial、矛盾、scope復元不能、またはcaller不明ならfinal initial read passへ進まず停止する。
5. authoritative hosted identity bindingを同じ規則で再解決してから、全Codex taskを同じ引数とscope復元規則で再取得してfinal initial read passを作る。各passでcurrent runのledgerをexact item IDへ一意に対応し、callerのscope anchor / fingerprintからそのitemだけを除外する。最初のpassとtask ID、`hostId`、canonical local / hosted identity binding、`cwd`、live status、正規化後のscope anchor chain、scope fingerprint、final classificationが一致し、unfinishedなtarget-relevant `mutating-or-unknown` invocationがなく、全callが完全なら、最後の`read_thread`の次のtool callとしてGit snapshot取得を開始する。差分または失敗があればGit snapshotを取らず、Workflow 9と同じ全体retry制限でguardを最初からやり直す。
6. scriptが存在する場合は120秒のhard deadlineでUgen preflightを1回実行して契約を検証し、発行したexact invocationをguard-owned ledgerへ追加する。invalidまたはtimeoutならGit証拠を不完全として開始・競合判定をblockする。
7. path lookupが`ENOENT`を返した場合だけ、fallback Git snapshotを集める。
   - `git worktree list --porcelain -z`
   - 各worktreeについて `git -C <worktree> status --porcelain=v1 -z --untracked-files=all --no-renames`
   - 収集直後に`git worktree list --porcelain -z`と全worktreeのstatusを再取得し、inventory A / Bを比較する
8. fallbackでは発行した各exact invocationをguard-owned ledgerへ追加する。worktree inventory AもNUL区切りのporcelain fieldとしてparseする。次にfreshまたはpinnedなbaseline ref / SHAと全worktreeのHEAD SHAを固定し、各HEADのcommitted pathsを収集する。statusはNUL区切りのporcelain v1 recordとしてparseし、XY列からstaged / unstaged / untracked pathを分類する。収集直後に同じparseでworktree一覧と全statusをinventory Bとして取得し、A / Bのworktree集合、各tuple、各status path分類、およびdiffに使った固定HEAD SHAの一致を検証する。malformed、truncated、unknown、directory集約のrecord、またはinventory差分が1件でもあればsnapshotを破棄し、共有された全体retry上限に従う。
9. preflightまたはfallback Git snapshot後、次の順でpost-preflight snapshotを取得する。
   1. authoritative hosted identity bindingを同じ規則で再解決し、initialと同じlimitの`list_threads`とrepository identityの対応付けからinventory Aを作り、coverageを記録する。guardが発行した各repository identity probeをpurpose付きでguard-owned ledgerへ追加する。
   2. Aの全Codex taskを同じ引数とscope復元規則の`read_thread`で取得してscope Aとfinal classificationを作る。
   3. authoritative hosted identity bindingを同じ規則でもう一度解決し、initialと同じlimitの`list_threads`とrepository identityの対応付けからinventory Bを作り、coverageを記録する。guardが発行した各repository identity probeをpurpose付きでguard-owned ledgerへ追加する。
   4. Bの全Codex taskを同じ引数とscope復元規則の`read_thread`で取得してscope Bとfinal classificationを作る。
   post-readでcallerのboundary後にあるledger項目を発行順、tool名、canonical argumentsからexact item IDへ一意に対応付ける。callerだけ、そのexact `guard-owned` itemをA / Bのscope anchor / fingerprintから除外し、他のitemと他taskには同じ除外を適用しない。全taskを再分類し、final initial、A、Bで、全返却taskのcoverage、task ID、`hostId`、identity classification、canonical local / hosted identity binding、`cwd`、live status、正規化後のscope anchor chain、scope fingerprint、final classificationが一致し、unfinishedなtarget-relevant `mutating-or-unknown` invocationがないことを要求する。`bounded latest N`の境界変化、hosted identity bindingの変化や`outside-repo` / `target-scoped` / `unscoped`間の変化もtask集合の差分として扱う。差分があれば新しいtaskを古いGit snapshotへ追加せず、開始判断をblockしてguard全体を最初からやり直す。taskまたはGit inventory変化による全体retryは共有して1回までとし、再び変化した場合はinventory unstableとして停止する。
10. same-repoの`target-scoped` taskだけ、`cwd`をcanonical absolute worktree pathへ境界付き最長一致で対応付ける。対応不能または同長の複数候補は`unscoped`とする。cross-repoの`target-scoped` taskはcwdをworktreeへ対応付けず、復元したscopeをplanned ownershipの証拠として全worktreeと新しい予定scopeへ直接比較する。対応する対象worktreeやGit diffがまだなくても、このplanned ownershipを破棄または縮小しない。validなpreflightでは`changes`を実際にmaterializeしたGit差分証拠、`fileOverlaps`を既存worktree同士の重複候補抽出に使うが、それだけで競合と断定しない。
11. Git証拠が不完全、task sourceがpartial / error、callerを一意に特定できない、または`unscoped` taskが残る場合は、契約違反、target-scoped task inventory、`unscoped` taskを分けて報告し停止する。coverageが`bounded latest N`なら既知の競合判定後も`green`にせず、`coverage-limited`としてユーザー判断を求める。
12. 新しい作業の予定file、symbol、責務、仕様を、live taskとの対応有無にかかわらず、変更のある全worktreeの`changes`と比較する。
13. live taskの現在scopeとcoverageを加えてcoverage-limited / green / yellow / redを判定する。
14. exhaustive coverageでgreen / yellowなら作業領域を提案する。bounded coverageでは、承認された`coverage risk fingerprint`と再guard後のfingerprintが完全一致した`coverage-limited override`の場合だけ作業領域を提案する。ユーザーが作成まで求めたら、その場でbranch / worktreeを作る。
15. `red`でも同じ所有taskが続けるのが適切なら、新しい作業領域を作らず、global `AGENTS.md`の後続依頼ルールに従う。
16. guard後にcallerが予定file、symbol、責務、仕様を追加または変更する場合は、stableなassistant messageで追加scopeを明示し、そのscopeへ最初に編集または外部変更を行う前にguard全体を再実行する。元のguard結果を拡張scopeへ流用しない。
17. 開始可否、停止、または再実行要求をユーザーへ返す直前に、versioned `guard provenance record`をstableなassistant message itemとして残す。早期停止でも発行済みattemptを省略せず、item対応不能なら`complete: false` / `itemId: null`で残す。recordを後続runのscope anchorにせず、完全なboundary historyで一意に補完・照合できたexact invocationだけをhistorical `guard-owned`として扱う。

# Conflict Levels

- `coverage-limited`
  - latest Nより古いtaskのscope ownershipが未確認
  - 既知のyellow / redがなくてもgreenとは呼ばない
- `green`
  - task inventory coverageがexhaustive
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
| `coverage-limited` | Nと未知のownership riskを示してユーザー判断を待つ。進行指示後も再guardし、`coverage-limited override`と報告する |
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
- follow-upの予定file、symbol、責務、仕様が、snapshotで確認できる対象taskの現在scopeにすべて含まれる場合だけ送信する。この条件は対象taskのidle / runningにかかわらず必須とし、既に見えているscopeがownershipを保持する。follow-upが現在scopeを拡張する場合、current toolsではobserved statusを条件にしたatomic sendも、後続guardが再取得できるdurable reservationもないため送信しない。対象taskでのユーザー操作など、`send_message_to_thread`を使わない明示的な調整が必要と報告する。
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
3. live `status`とscopeを確認したsame-repo / cross-repoの`target-scoped` task、scope確認後に除外した`outside-repo` task、identityまたはscope未確認の`unscoped` task
   - task inventory coverageが`bounded latest N`なら、N、「それより古いtaskは未確認」、判定が`coverage-limited`であることを明記する
4. 重複または競合の根拠
5. 推奨する作業領域
6. 後続キューへ積んだ場合は、対象セッション名・ID・受付状態
7. 実際に作成した path / branch があればその場所

# Notes

- taskのactive / idleは必ず`list_threads`のlive `status`で判断する。
- `bounded latest N`をtask履歴全体のcomplete inventoryまたはgreenと呼ばない。競合判定は「最新N件のscopeと全worktreeのGit状態に基づくcoverage-limited判定」と表現する。
- repository identityはtaskの通常の所属先を絞る一次証拠にだけ使い、対象repoへ関与しない証拠またはGit状態の証拠として扱わない。
- task確認より前に取得したGit snapshotからgreen / yellowを判定しない。
- このguardは時点をそろえたsnapshot確認でありlockではない。開始可能と判断した作業領域は直ちに使い、新しいtask / worktree activity、stableなassistant messageによるscope拡張を観測した場合や開始が遅れて鮮度を保証できない場合は、そのscopeへの編集前にguardをやり直す。
- `read_thread`から復元したscopeは、未着手を含むplanned ownershipの証拠とする。cleanまたはGit diffなしをplanned ownership不在の証拠にしない。
- validなpreflightの`changes`またはfallback時のGit diffは、対応するworktreeがあるtaskについて、実際にmaterializeした変更の追加証拠として使う。Git側がscopeより広い、またはscopeと矛盾する場合はownershipを縮小せず、観測範囲を広げるかfail closedにする。
- cross-repoの`target-scoped` taskは、対象worktreeが対応付かなくても復元scopeだけでplanned ownershipを成立させる。対象worktreeを実際に対応付けられる場合だけGit差分も追加で照合する。
- `main の作業を確認して`のような依頼では、task指定がなくてもlive task inventoryと、validなpreflightのbaseline / `changes`、またはfallback時のcurrent `main` commit / diffを確認する。
