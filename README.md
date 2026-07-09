# Agent Skills

Codex、Claude、Grok Build で共通利用する個人用 skills の管理リポジトリです。

## 何を管理しているか

このリポジトリの `skills/` が source of truth です。

実際に Codex / Claude / Grok Build が読む場所には、`skills/` への symlink を置きます。

```text
~/.codex/skills/<skill-name>  ->  ./skills/<skill-name>
~/.claude/skills/<skill-name> ->  ./skills/<skill-name>
~/.grok/skills/<skill-name>   ->  ./skills/<skill-name>
```

つまり、skill を追加・編集・削除するときは、基本的にこのリポジトリの
`skills/` を変更します。

## 普段の使い方

skill を編集したら、通常どおり commit します。

```sh
git status
git add -A
git commit -m "Update skills"
git push
```

この clone では git hook を設定しているため、`git commit` 後に自動で
`./scripts/sync-live.sh` が走り、Codex / Claude / Grok Build の runtime 側へ反映されます。

`git pull` や `git merge` の後も自動で同期されます。

## 手動で反映する

commit せずに今すぐ runtime 側へ反映したい場合は、手動で同期します。

```sh
./scripts/sync-live.sh
```

この script は以下を行います。

- `skills/*` を `~/.codex/skills/*` に symlink する
- `skills/*` を `~/.claude/skills/*` に symlink する
- `skills/*` を `~/.grok/skills/*` に symlink する
- 以前この repo で管理していたが、今は `skills/` から消えた skill を runtime 側から削除する
- Codex の `.system` や plugin 由来の skills など、この repo 管理ではないものは触らない

## hook を設定する

別マシンや新しい clone では、一度だけ hook を設定します。

```sh
./scripts/install-hooks.sh
```

これで `git commit` / `git pull` / `git merge` の後に自動同期されます。

編集中の壊れた `SKILL.md` が勝手に反映されないよう、保存時の自動同期にはしていません。
commit や pull のように、状態が固まったタイミングだけ反映します。

Grok Build は Claude Code の skills も自動で読むようですが、この repo では xAI 用の
明示的な同期先として `~/.grok/skills/` も管理します。

## upstream skills を更新する

`mattpocock/skills` など外部の skills を更新するときは、上書きではなく差分マージとして扱います。

基本の流れ:

```sh
tmpdir=$(mktemp -d /tmp/mattpocock-skills.XXXXXX)
git clone --depth 1 --branch v1.1.0 https://github.com/mattpocock/skills.git "$tmpdir"
```

そのあと、必要な skill を `skills/` にコピーまたは手作業でマージします。

注意点:

- rename された skill は、必要なら旧名を互換 alias として残す
- ローカルで独自に作った skill は消さない
- 削除した skill は `./scripts/sync-live.sh` が runtime 側から prune する

最後に確認して commit / push します。

```sh
./scripts/sync-live.sh
git diff
git add -A
git commit -m "Update upstream skills"
git push
```
