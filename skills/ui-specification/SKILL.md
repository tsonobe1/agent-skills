---
name: ui-specification
description: Resolve and record UI presentation and interaction decisions before defining UI work, creating implementation issues, or implementing UI changes, including ordinary requests without a named skill.
---

# UI specification

Before defining UI work, publishing implementation issues, or changing production UI:

1. Identify every affected surface. Reuse applicable approved UI specifications with a reference, without asking for approval again. If presentation and interaction are unaffected, continue normally.
2. For missing UI decisions, inspect the existing UI and propose what appears where, its information hierarchy, user operations, and relevant states such as empty, long, or multiple values. Use a sketch or mock when placement or appearance needs visual judgement, and obtain user agreement.
3. Include a concise UI specification, the agreed design reference, and the approval reference in each implementation issue. Cover each surface separately; “display a label” alone is insufficient.
4. If an existing issue lacks these decisions, agree and record them before production changes. Until then, keep the work in design: publish an implementation issue or mark it `ready-for-agent` only after the UI specification is settled. A design-only issue may be created when requested.

An implementation request or passing functional checks does not settle missing UI decisions.
