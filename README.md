# Agent Skills

Codex、Claude、Grok Build で共通利用する個人用 skills の管理リポジトリです。

## 責務と chezmoi との分担

このリポジトリは、スキルの本文・参考資料・補助スクリプトと、その変更履歴を管理します。
PC の設定ファイルは [chezmoi-dotfiles](https://github.com/tsonobe1/chezmoi-dotfiles) が管理します。

| やりたいこと | 編集先・使うもの |
| --- | --- |
| スキルの内容を変える | このリポジトリの `skills/` |
| スキルを追加・削除・改名する | `skills/` を変更し、`./scripts/sync-live.sh` でリンクを整える |
| スキルの変更を GitHub に保存する | このリポジトリで commit / push |
| シェル・Git・Codex 共通指示などを変える | `chezmoi-dotfiles` を編集し、`chezmoi diff` → `chezmoi apply` |
| 新しい PC に環境を用意する | `chezmoi-dotfiles` のセットアップ後、このリポジトリの hook を設定する |

日常のスキル編集は、このリポジトリから各ツールへのリンクでつながっています。
chezmoi は初回などの環境準備で、このリポジトリを取得して同期スクリプトを呼びます。
スキル本体の編集・更新は、このリポジトリ側で行います。

## 何を管理しているか

このリポジトリの `skills/` が source of truth です。

実際に Codex / Claude / Grok Build が読む場所には、原則として `skills/` への symlink を置きます。

```text
~/.codex/skills/<skill-name>  ->  ./skills/<skill-name>
~/.claude/skills/<skill-name> ->  ./skills/<skill-name>
~/.grok/skills/<skill-name>   ->  ./skills/<skill-name>
```

つまり、skill を追加・編集・削除するときは、基本的にこのリポジトリの
`skills/` を変更します。

各ツール側に置くのはコピーではなく、本体へのリンク（ショートカット）です。
リンク済みのスキルは、本体を編集すると次にファイルを読み込んだときに編集後の内容が読まれます。
編集のたびに同期スクリプトを実行する必要はありません。
すでに会話内に読み込まれた内容の更新や、新しいスキルの検出は、各ツールの読み込み動作に従います。

## 普段の使い方

`skills/` を編集し、差分を確認してから対象ファイルを commit / push します。

```sh
git status --short
git diff
git add -- skills
git diff --cached
git commit -m "Update skills"
git push
```

この clone では git hook を設定しているため、`git commit` 後に自動で
`./scripts/sync-live.sh` が走り、追加・削除などに合わせて各ツール側のリンクを整えます。

`git merge` と、merge を伴う `git pull` の後にも同期されます。
rebase ではこの hook は動かないため、追加・削除を取り込んだ場合は手動で同期します。

## 手動でリンクを整える

新しいスキルを commit 前に使いたい場合や、追加・削除・改名後にリンクを整えたい場合に実行します。

```sh
./scripts/sync-live.sh
```

この script は以下を行います。

- 現在は同じスキルを Codex / Claude / Grok Build の各スキル置き場に symlink する
- `skills/` 直下の README やライセンスファイルは Codex 側に symlink する
- 以前この repo で管理していたが、今は `skills/` から消えた skill を runtime 側から削除する
- `.system` や plugin のキャッシュなど、この repo のスキル名と管理記録に含まれない配置先は変更しない

配置先に同名のファイルやフォルダがある場合はリンクに置き換えるため、同期前に内容を確認します。

## hook を設定する

別マシンや新しい clone では、一度だけ hook を設定します。

```sh
./scripts/install-hooks.sh
```

これで `post-commit` / `post-merge` hook が有効になります。
chezmoi 側の準備処理は、この hook 設定までは行いません。

hook が行うのはリンクの整備です。既存リンク先の編集内容は、commit 前から読み取り可能です。

## upstream skills を更新する

`mattpocock/skills` など外部の skills を更新するときは、上書きではなく差分マージとして扱います。

基本の流れ:

```sh
tmpdir=$(mktemp -d /tmp/mattpocock-skills.XXXXXX)
git clone --depth 1 --branch v1.2.3 https://github.com/mattpocock/skills.git "$tmpdir"
```

そのあと、必要な skill を `skills/` にコピーまたは手作業でマージします。

注意点:

- rename された skill は、必要なら旧名を互換 alias として残す
- ローカルで独自に作った skill は消さない
- upstream 由来の skill にローカル変更を加えたら、`skills/README.md` の「Upstream Skills のローカル変更」も更新する
- 削除した skill は `./scripts/sync-live.sh` が runtime 側から prune する

最後に確認して commit / push します。

```sh
./scripts/sync-live.sh
git diff
git add -- skills
git commit -m "Update upstream skills"
git push
```
