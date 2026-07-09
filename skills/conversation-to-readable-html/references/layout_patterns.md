# Layout Patterns

Use these patterns as starting points. Adapt the structure to the content instead of forcing every block into every document.

## Base Shell

```html
<!doctype html>
<html lang="ja">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>...</title>
  <style>
    :root {
      color-scheme: light;
      --bg: #f8fafc;
      --surface: #ffffff;
      --text: #111827;
      --muted: #6b7280;
      --border: #e5e7eb;
      --accent: #2563eb;
      --accent-bg: #eff6ff;
      --warn: #f59e0b;
      --warn-bg: #fffbeb;
      --ok: #16a34a;
      --bad: #dc2626;
    }

    * { box-sizing: border-box; }

    body {
      margin: 0;
      font-family: system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
      line-height: 1.8;
      color: var(--text);
      background: var(--bg);
    }

    .document {
      max-width: 960px;
      margin: 0 auto;
      padding: 48px 24px;
    }

    .hero,
    .summary-card,
    .conclusion-card,
    .decision-card,
    .in-short,
    .term,
    .warning {
      background: var(--surface);
      border: 1px solid var(--border);
      border-radius: 8px;
      padding: 24px;
      margin: 24px 0;
    }

    .hero h1 {
      margin: 8px 0 12px;
      font-size: clamp(2rem, 5vw, 3.2rem);
      line-height: 1.15;
    }

    .eyebrow {
      margin: 0;
      color: var(--accent);
      font-weight: 700;
      letter-spacing: 0;
    }

    .lead {
      color: var(--muted);
      font-size: 1.1rem;
      margin-bottom: 0;
    }

    .in-short {
      border-left: 6px solid var(--accent);
      background: var(--accent-bg);
    }

    .warning {
      border-left: 6px solid var(--warn);
      background: var(--warn-bg);
    }

    .comparison-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
      gap: 16px;
      margin: 20px 0;
    }

    .option-card {
      background: var(--surface);
      border: 1px solid var(--border);
      border-top: 4px solid var(--accent);
      border-radius: 8px;
      padding: 18px;
    }

    .toc {
      position: sticky;
      top: 0;
      z-index: 1;
      background: rgba(248, 250, 252, 0.95);
      border-bottom: 1px solid var(--border);
      padding: 12px 0;
      backdrop-filter: blur(8px);
    }

    .toc a {
      display: inline-block;
      margin: 4px 12px 4px 0;
      color: var(--accent);
      text-decoration: none;
      font-weight: 600;
    }

    code, pre {
      background: #f1f5f9;
      border-radius: 6px;
    }

    code { padding: 2px 6px; }
    pre { padding: 16px; overflow-x: auto; }

    table {
      width: 100%;
      border-collapse: collapse;
      margin: 20px 0;
      background: var(--surface);
    }

    th, td {
      border: 1px solid var(--border);
      padding: 10px 12px;
      vertical-align: top;
    }

    th {
      background: #f3f4f6;
      text-align: left;
    }

    details {
      background: var(--surface);
      border: 1px solid var(--border);
      border-radius: 8px;
      padding: 16px 18px;
      margin: 18px 0;
    }

    @media (max-width: 640px) {
      .document { padding: 28px 16px; }
      .hero, .summary-card, .conclusion-card, .decision-card, .in-short, .term, .warning {
        padding: 18px;
      }
      .toc { position: static; }
    }

    @media print {
      body { background: #fff; }
      .toc { position: static; }
      .document { max-width: none; padding: 0; }
    }
  </style>
</head>
<body>
  <main class="document">
    ...
  </main>
</body>
</html>
```

## Opening

```html
<header class="hero">
  <p class="eyebrow">Conversation Digest / Design Note</p>
  <h1>Chrome拡張とElectron連携方式の整理</h1>
  <p class="lead">WebSocket、Native Messaging、Safari連携案を比較し、MVPと長期設計の方針を整理する。</p>
</header>

<section class="summary-card" id="summary">
  <h2>これは何の話か</h2>
  <p>...</p>
</section>
```

## Conclusion

```html
<section class="conclusion-card" id="conclusion">
  <h2>結論</h2>
  <ul>
    <li>MVPではlocalhost WebSocketを使う。</li>
    <li>長期的にはNative Messagingへ移行できる境界を残す。</li>
    <li>SafariはmacOS companion app経由で別ブリッジとして扱う。</li>
  </ul>
</section>
```

## Research Evidence

```html
<section id="evidence">
  <h2>調査で確認したこと</h2>
  <h3>確認したかったこと</h3>
  <p>Safari拡張からElectronへ直接データを渡せるか。</p>

  <h3>確認できたこと</h3>
  <p>Safariでは拡張単体では完結せず、macOS側のアプリを介する必要がある。</p>

  <h3>そこから言えること</h3>
  <p>ChromeとSafariで完全に同じ構成にするより、ブラウザごとのブリッジ層を分ける設計が妥当。</p>
</section>
```

## Action List

```html
<section id="next-actions">
  <h2>次にやること</h2>
  <ol>
    <li>IPC境界を抽象化する。</li>
    <li>WebSocket実装をMVPとして作る。</li>
    <li>Native Messaging移行時の差し替えポイントを残す。</li>
  </ol>
</section>
```
