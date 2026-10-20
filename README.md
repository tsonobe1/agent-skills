# Agent Skills

**スキルを `skills/` で一元管理し、Codex・Claude・Grok Build のスキル置き場に
シンボリックリンクを作成するリポジトリです。** 各ツールはリンク経由で同じ本体を読みます。

```text
Codex: ~/.codex/skills/<name>   -> このリポジトリの skills/<name>
Claude: ~/.claude/skills/<name> -> このリポジトリの skills/<name>
Grok: ~/.grok/skills/<name>     -> このリポジトリの skills/<name>
```

## 普段の使い方

### 既存のスキルを編集する

`skills/<name>/SKILL.md` や、そのスキルの参考資料・補助スクリプトを編集します。
リンク済みなら、各ツールが次にファイルを読んだときに変更後の内容が読まれます。
編集のたびに同期スクリプトを実行する必要はありません。

変更を GitHub に保存するときは、差分を確認して commit / push します。

```sh
git status --short
git diff
git add -- skills
git diff --cached
git commit -m "Keep shared guidance consistent across agents"
git push
```

この clone では git hook を設定しているため、`git commit` 後に自動で
`./scripts/sync-live.sh` が走り、追加・削除などに合わせて各ツール側のリンクを整えます。

`git merge` と、merge を伴う `git pull` の後にも同期されます。
rebase ではこの hook は動かないため、追加・削除を取り込んだ場合は手動で同期します。

### スキルを追加・削除・改名する

`skills/` の追加・削除・改名後、次を実行して各ツール側のリンクを整えます。
新しいスキルを commit 前に使いたいときも、この操作です。

```sh
./scripts/sync-live.sh
```

すでに会話内に読み込まれた内容の更新や、新しいスキルの検出は、各ツールの読み込み動作に従います。

## 同期スクリプトが扱う範囲

この script は以下を行います。

- 現在は同じスキルを Codex / Claude / Grok Build の各スキル置き場に symlink する
- `skills/` 直下の README やライセンスファイルは Codex 側に symlink する
- 以前この repo で管理していたが、今は `skills/` から消えた skill を runtime 側から削除する
- `.system` や plugin のキャッシュなど、この repo のスキル名と管理記録に含まれない配置先は変更しない

配置先に同名のファイルやフォルダがある場合はリンクに置き換えるため、同期前に内容を確認します。

## 初期設定

別マシンや新しい clone では、一度だけ hook を設定し、最初のリンクを作成します。

```sh
./scripts/install-hooks.sh
./scripts/sync-live.sh
```

これで `post-commit` / `post-merge` hook が有効になります。

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

## chezmoi との関係

シェル・Git などの PC 設定は [chezmoi-dotfiles](https://github.com/tsonobe1/chezmoi-dotfiles) が管理します。
chezmoi は初回などの環境準備で、このリポジトリを取得して同期スクリプトを呼びます。
Git hook の有効化は、上記の「初期設定」で別途行います。
普段のスキル編集・同期・commit / push は、このリポジトリで行います。
