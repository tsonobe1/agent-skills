# Skills

Codex と Claude に同期する skills 一覧です。

## Upstream: mattpocock/skills v1.1.0

### User-invoked

明示的に呼び出す skills です。上流では `disable-model-invocation: true` のものです。

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

### Model-invoked

モデルが状況に応じて自動で使える skills です。ユーザーが明示的に呼んでも構いません。

- **[prototype](./prototype/SKILL.md)** - throwaway prototype で設計上の疑問を検証する。
- **[diagnosing-bugs](./diagnosing-bugs/SKILL.md)** - bug / performance regression の診断 loop。
- **[research](./research/SKILL.md)** - primary source 調査をまとめる。
- **[tdd](./tdd/SKILL.md)** - TDD の参照 skill。
- **[domain-modeling](./domain-modeling/SKILL.md)** - domain language と ADR / CONTEXT を育てる。
- **[codebase-design](./codebase-design/SKILL.md)** - deep modules や seam の設計語彙。
- **[code-review](./code-review/SKILL.md)** - diff を Standards / Spec の二軸で review する。
- **[resolving-merge-conflicts](./resolving-merge-conflicts/SKILL.md)** - merge / rebase conflict を解く。
- **[grilling](./grilling/SKILL.md)** - reusable grilling loop。

## Local Skills

この repo 独自または別 upstream 由来の skills です。
`implement` にはローカル方針として、テストを追加・変更・削除した場合に `tdd-review` で
`test-case-principles` に照らすルールを足しています。
`code-review` にはローカル方針として、Standards 軸で `review-standards` を読む
ルールを足しています。

- **[conversation-to-readable-html](./conversation-to-readable-html/SKILL.md)**
- **[playwright](./playwright/SKILL.md)**
- **[review-standards](./review-standards/SKILL.md)**
- **[session-resume-check](./session-resume-check/SKILL.md)**
- **[tdd-review](./tdd-review/SKILL.md)**
- **[test-case-principles](./test-case-principles/SKILL.md)**
- **[zoom-out](./zoom-out/SKILL.md)**
