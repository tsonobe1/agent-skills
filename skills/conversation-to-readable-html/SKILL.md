---
name: conversation-to-readable-html
description: Convert conversation logs, research findings, design notes, implementation notes, reviews, or long decision discussions into a visually scannable single self-contained HTML document. Use when the user asks to HTML化, make a readable HTML report, turn notes into a browser-viewable document, or preserve chat, research, or design content for later review.
---

# Conversation To Readable HTML

Convert input content into a single self-contained HTML file that can be opened locally in a browser.

## Use When

- The user asks to HTML化, create a readable HTML report, or preserve a conversation, research note, design note, implementation note, review, or decision discussion for later review.
- Do not use this for normal Markdown cleanup, public publishing, or app UI implementation unless the user explicitly asks for a local single-file HTML artifact.

## Goal

Produce a browser-openable local HTML document that helps the reader understand the topic, conclusion, evidence, unresolved questions, and next actions faster than reading the original source order.

## Done

- The artifact is one self-contained `.html` file with inline CSS and no external dependencies.
- The opening explains what the document is about and the current conclusion or decision state.
- Facts, decisions, assumptions, unresolved questions, and next actions are separated when they exist.
- `scripts/check_html.py <file.html>` passes, or the blocker and next-best validation are reported.

## Stop

Stop and ask before continuing when:

- the user has not provided enough source material to identify the topic or conclusion
- the requested artifact requires publishing, sharing, or uploading outside the local filesystem
- the source contains sensitive material and the requested destination is unclear

## Core Rule

Do not merely format the input. Rebuild it into the fastest path for reader understanding.

The output is not a cleaned-up transcript. It is a readable decision, research, design, or implementation document.

Keep these distinctions explicit:

- confirmed facts
- decisions
- assumptions
- unresolved questions
- next actions

## Workflow

1. Identify the document mode:
   - `research-note`: what was checked, what was confirmed, and how it affects the decision.
   - `design-note`: options, tradeoffs, adopted decisions, rejected options, risks, and open questions.
   - `implementation-note`: implementation direction, TODOs, acceptance criteria, tests, and next actions.
   - If the user does not choose a mode, infer the nearest mode from the content.
2. Extract facts, decisions, assumptions, unresolved questions, and next actions before writing HTML.
3. Reorder the content by reader understanding, not by conversation chronology.
4. Write one complete HTML document with inline CSS and no external dependencies.
5. Save it as a local `.html` file in a sensible location for the current task.
6. Run `scripts/check_html.py <file.html>` and fix any reported issues before returning the path.

## Output

Final response should state the artifact path, what the reader can now use it for, validation result, and any unresolved source or validation gaps.

## Required Opening

Start with the reader's orientation:

- what this document is about
- why this discussion was needed
- what was decided, or where the current conclusion stands

Use a short problem-awareness lead when helpful. For Japanese content, this often works well:

```html
<section class="summary-card">
  <h2>これは何の話か</h2>
  <p>...</p>
</section>
```

## Default Structure

Use this order by default. Omit sections that do not apply.

1. Title
2. What This Is About / これは何の話か
3. Conclusion / 結論
4. Background or Problem / 背景・問題意識
5. Options Considered / 検討した選択肢
6. Decision Rationale / 判断理由
7. Details / 詳細メモ
8. Decisions / 決定事項
9. Open Questions / 未決事項
10. Next Actions / 次にやること
11. References / 参考リンク・出典
12. Supplemental Log / 元会話・補足ログ

For long documents, include a table of contents near the top.

## Section Pattern

Put the conclusion early. For design and implementation notes, prefer:

1. conclusion
2. rationale
3. options considered
4. details
5. remaining issues

For major sections, add a short recap block:

```html
<div class="in-short">
  <strong>要するに：</strong>
  <p>...</p>
</div>
```

Do not force an `in-short` block after tiny sections.

## Research Handling

Write research as decision evidence, not as a source-by-source literature review.

Use this order:

- what needed to be checked
- what was confirmed
- how it affects the current decision

Separate official facts from inference. Use wording such as `確認できたこと`, `そこから言えること`, and `現時点では` when the evidence is limited.

## Conversation Handling

- Do not list user questions verbatim unless the exact wording matters.
- Convert each question into the underlying issue.
- Move detailed back-and-forth to the supplemental log.
- Preserve important caveats, disagreements, and reversals.

Examples:

- `native host必要？` -> `Safari Web Extensionでネイティブ連携する場合、macOS側の受け口が必要か`
- `WebSocketでも同じ？` -> `Electron mainとの通信手段としてWebSocketを使う場合の差分`

## Term Handling

Explain technical terms once, at first use, and only in the current context.

```html
<aside class="term">
  <strong>Native Messaging</strong>
  <p>ブラウザ拡張が、OS上のネイティブアプリと安全に通信するための公式な仕組み。</p>
</aside>
```

Avoid long dictionary definitions.

## HTML Rules

- Produce a single `.html` file.
- Include `<!doctype html>`, `<html lang="...">`, `<meta charset="utf-8">`, and responsive viewport metadata.
- Use inline CSS in a `<style>` block.
- Do not use external CSS, external JavaScript, CDN assets, remote fonts, or tracking pixels.
- Use inline SVG or HTML/CSS diagrams by default.
- Use Mermaid only when the user explicitly allows external rendering or the target environment already supports it.
- Keep the original language of the input.
- Use light backgrounds by default.
- Use accessible heading order, descriptive links, and readable contrast.
- Put raw conversation excerpts in `<details>` blocks when needed.

For detailed reusable layout patterns, read `references/layout_patterns.md`.

## Validation

Run:

```bash
python3 ~/.codex/skills/conversation-to-readable-html/scripts/check_html.py path/to/output.html
```

Fix issues before delivering. If browser validation is useful and a local URL or file path is available, open it with the Browser skill or another appropriate browser tool and inspect the rendered result.
