---
name: group-feature
description: Create a parent feature issue from existing implementation ticket issues, attach them as sub-issues, and write a human verification checklist that covers the child acceptance criteria.
disable-model-invocation: true
---

# Group Feature

Turn a flat set of implementation ticket issues into one feature parent with child issues.

Use this after `/to-tickets` has created implementation tickets, or when the user wants to organize existing issues under a feature issue.

## Process

### 1. Gather the child issues

Read every issue the user passed. Fetch the full body, labels, comments if relevant, and current parent/sub-issue state when the tracker exposes it.

If the user did not pass issue numbers, ask for the exact child issues before creating or editing tracker state.

### 2. Choose the feature shape

Derive a short feature title from the common user-visible outcome of the child issues. The title should describe the feature, not the bookkeeping action.

Draft the parent issue body with:

- `## Feature` — what the whole feature enables from the user's perspective.
- `## Child issues` — links to every child issue.
- `## Human verification checklist` — manual checks that cover the child acceptance criteria.
- `## Done` — "All child issues are closed and the human verification checklist is complete."

The parent issue is a coordination and verification artifact. Apply the `feature` label. Do not apply `ready-for-agent` unless the user explicitly asks, because implementation work belongs to the child issues.

### 3. Build the human verification checklist

Read the child issues' acceptance criteria and "what to build" sections. Produce a checklist that is complete against those criteria but written as human-observable behavior.

Checklist rules:

- Cover every child issue acceptance criterion, either directly or through a merged broader check.
- Merge duplicates across child issues.
- Translate implementation-only or test-only criteria into observable behavior when possible.
- Leave non-manual criteria out of the parent checklist only when a human cannot realistically verify them; keep them on the child issue.
- Add child issue references to each checklist item, such as `(#101)` or `(#101, #102)`.
- Prefer end-to-end checks over layer-by-layer checks.

Before publishing, present the proposed parent title and checklist and ask the user to approve or edit it. Do not create the parent issue until the user approves.

### 4. Publish the parent issue

Create one parent issue in the configured tracker. On GitHub, use `gh issue create` and apply the `feature` label. If the label does not exist, create or ask before creating based on the repository's existing label policy.

Use this parent issue template:

```md
## Feature

<What the feature enables.>

## Child issues

- #<child>
- #<child>

## Human verification checklist

- [ ] <Human-observable check.> (#<child>)
- [ ] <Human-observable check.> (#<child>, #<child>)

## Done

All child issues are closed and the human verification checklist is complete.
```

### 5. Attach child issues

Attach every child issue to the new parent using the tracker native sub-issue relationship when available.

On GitHub, prefer the REST sub-issues API over body-only links:

1. Get the child issue node/database ID with `gh issue view <child> --json id`.
2. Add it under the parent with `gh api repos/{owner}/{repo}/issues/<parent>/sub_issues -f sub_issue_id=<child-id>`.

If a child already has a different parent, stop and ask before replacing it. If native sub-issues are unavailable, update the parent body task list and add a `Parent: #<parent>` line to each child issue body.

### 6. Report the result

Return:

- Parent issue number and title.
- Child issues attached.
- Whether native sub-issues were used or a fallback was used.
- Any child acceptance criteria that could not become human verification checks.
