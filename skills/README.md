# Skills

Codex、Claude、Grok Build に同期する skills 一覧です。

## Upstream: mattpocock/skills v1.1.0

### User-invoked

明示的に呼び出す skills です。この repo では `disable-model-invocation: true` を設定しています。

- **[ask-matt](./ask-matt/SKILL.md)** - Matt Pocock skill set の router。
- **[grill-with-docs](./grill-with-docs/SKILL.md)** - codebase 前提の grilling と docs 更新。
- **[implement](./implement/SKILL.md)** - spec / ticket を実装する flow。
- **[improve-codebase-architecture](./improve-codebase-architecture/SKILL.md)** - codebase の設計改善候補を探す。
- **[setup-matt-pocock-skills](./setup-matt-pocock-skills/SKILL.md)** - repo ごとの issue tracker / docs 設定。
- **[to-spec](./to-spec/SKILL.md)** - 会話内容を spec にまとめる。
- **[to-tickets](./to-tickets/SKILL.md)** - spec / plan を tickets に分割する。
- **[triage](./triage/SKILL.md)** - issue / external PR を triage する。
- **[wayfinder](./wayfinder/SKILL.md)** - 大きすぎる作業を探索 ticket map に分解する。
- **[grill-me](./grill-me/SKILL.md)** - codebase なしで計画を詰める grilling。
- **[handoff](./handoff/SKILL.md)** - 会話を handoff document にまとめる。
- **[teach](./teach/SKILL.md)** - 複数 session で概念を教える。
- **[writing-great-skills](./writing-great-skills/SKILL.md)** - skill を書くための参照。
- **[code-review](./code-review/SKILL.md)** - 抽象化、巨大ファイル、spaghetti growth を厳しく検査する保守性 review。

### Model-invoked

モデルが状況に応じて自動で使える skills です。ユーザーが明示的に呼んでも構いません。

- **[prototype](./prototype/SKILL.md)** - throwaway prototype で設計上の疑問を検証する。
- **[diagnosing-bugs](./diagnosing-bugs/SKILL.md)** - bug / performance regression の診断 loop。
- **[research](./research/SKILL.md)** - primary source 調査をまとめる。
- **[tdd](./tdd/SKILL.md)** - TDD の参照 skill。
- **[domain-modeling](./domain-modeling/SKILL.md)** - domain language と ADR / CONTEXT を育てる。
- **[codebase-design](./codebase-design/SKILL.md)** - deep modules や seam の設計語彙。
- **[resolving-merge-conflicts](./resolving-merge-conflicts/SKILL.md)** - merge / rebase conflict を解く。
- **[grilling](./grilling/SKILL.md)** - reusable grilling loop。

## Upstream Skills のローカル変更

Matt Pocock の v1.1.0 を元に、次の4つにローカル変更があります。
upstream を更新するときは、これらを上書きせず差分マージします。

- **[implement](./implement/SKILL.md)** - テストを追加・変更・削除した場合、`tdd-review` を実行して `test-case-principles` に照らします。
- **[code-review](./code-review/SKILL.md)** - Standards / Spec の二軸 review を、保守性と構造的単純化に集中する user-invoked review へ置き換えています。
- **[tdd](./tdd/SKILL.md)** - テスト作成前と各 red → green cycle で、ローカルの `test-case-principles` を必須参照にしています。
- **[to-tickets](./to-tickets/SKILL.md)** - ticket 作成後、必要に応じて `group-feature` で親 feature Issue と human verification checklist を作ります。

## Local Skills

この repo 独自または別 upstream 由来の skills です。

### User-invoked

明示的に呼び出す skills です。`disable-model-invocation: true` を設定しています。

- **[group-feature](./group-feature/SKILL.md)** - 既存 tickets を子に持つ親 feature Issue と動作確認 checklist を作る。
- **[zoom-out](./zoom-out/SKILL.md)** - codebase を一段上の視点から捉え直し、関連範囲の全体像を示す。

### Model-invoked

モデルが状況に応じて自動で使える skills です。ユーザーが明示的に呼んでも構いません。

- **[conversation-to-readable-html](./conversation-to-readable-html/SKILL.md)** - 会話や調査結果を読みやすい単一 HTML にまとめる。
- **[playwright](./playwright/SKILL.md)** - 実ブラウザを操作して画面確認やデータ取得を行う。
- **[review-standards](./review-standards/SKILL.md)** - repo の規約を補う個人用 code review 基準を適用する。
- **[session-resume-check](./session-resume-check/SKILL.md)** - 再接続後に作業状況と次の安全な手順を復元する。
- **[tdd-review](./tdd-review/SKILL.md)** - 追加・変更・削除された tests の品質をレビューする。
- **[test-case-principles](./test-case-principles/SKILL.md)** - 振る舞いに焦点を当てた test case 設計原則を提供する。
