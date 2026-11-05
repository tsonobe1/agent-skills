---
name: hypothesis-and-evidence
description: Express and challenge user-owned hypotheses, define verification before implementation, and report evidence and AI decisions. Use when discussing features or designs, writing specs or issues, starting substantive implementation work, or reviewing its results.
---

# Hypothesis and Evidence

Follow the section for the current stage and carry the same record forward. Reuse settled user statements and decisions. A conversation may hold the initial record; persist it when the user requests a spec or Issue, or when an invoked documentation skill calls for it. Loading this skill does not authorize implementation, publication, or Git operations. Repository guides retain authority over execution commands, review, and completion.

## Express the user's hypothesis

Start from what the user knows and has said. Distinguish observed facts, the user's hypothesis, and assumptions proposed by the AI. A hypothesis states who should benefit, in what situation, what change is expected to help, and why.

Help formulate an incomplete hypothesis through discussion. Label an AI draft as a proposal; attribute it to the user only when their statements or confirmation support that attribution. Record the relevant observations, hypothesis, AI assumptions, and unanswered questions in the current work record.

The hypothesis may change whenever circumstances, evidence, or understanding change. Retain the previous hypothesis, the new hypothesis, and the reason. Revising a hypothesis does not by itself authorize expanding scope or changing agreed behavior.

## Challenge and design together

Add these perspectives to the existing discussion or grilling process:

- **Counterargument**: a competing explanation or reason the proposed change might not produce the expected benefit.
- **Blind spots**: actors, situations, constraints, dependencies, and missing knowledge not yet expressed in the discussion.
- **Premortem**: suppose the proposed change was implemented and failed; examine a concrete failure scenario, its causes, and how to detect or prevent it.

Anchor the discussion in the user's actual problem. Identify hypothetical scenarios and unsupported claims as such. Carry the findings and remaining uncertainties into the spec or Issue. Preserve the calling skill's existing questions, branches, and completion rules.

The AI leads design exploration by presenting proposals, alternatives, reasons, and tradeoffs. The user can question the options and participate in decisions. Distinguish choices agreed with the user from choices made by the AI within the authorized scope. Preserve existing decision and approval rules.

## Define verification before implementation

Include an initial verification plan when creating a spec or Issue. At Issue start, confirm or refine it before implementation, reusing existing agreements. For work without an Issue, keep the plan in the current task record.

For each acceptance criterion, identify the starting conditions, action or measurement, observable expected result, pass/fail condition, evidence to retain, and what that check cannot establish. Select the verification level using the repository guide and the behavior being changed.

If the criteria must change, preserve the original criteria and any results already obtained, explain the reason, and resolve changes to agreed behavior with the user under existing scope rules. A failed, unavailable, or skipped check remains visible; changing criteria after seeing a result does not turn it into a success.

## Verify and show evidence

Compare results with the criteria declared before implementation. Report what actually ran or was observed: test cases or filter, command or action, reviewed source revision and relevant conditions, result, and the supporting evidence.

Provide the screenshots, logs, or traces needed for the claims and the repository's verification requirements. Do not infer observed runtime behavior from a build or unrelated passing tests. Keep secrets and unrelated personal data out of evidence.

State what was not performed or observed, why, and which conclusions remain unsupported. Distinguish implementation acceptance from evidence that the hypothesized user benefit occurs. Reuse valid earlier evidence according to repository rules rather than treating every check as requiring a fresh run.

## Recheck omissions and disclose AI decisions

After verification and before claiming completion, ask yourself **「何か見落としていない？」** Revisit the original intent, hypothesis, challenge findings, acceptance criteria, actual user path, and evidence boundaries. Give a concrete answer based on those materials.

Correct actionable omissions within the authorized scope and repeat affected checks. Report unresolved risks and follow-ups with their impact. Self-review does not replace required independent review or prove that no unknown problems remain.

Report what the AI decided on the user's behalf and why, including defaults, requirement interpretations, exclusions, and tradeoffs. Distinguish these from user-approved decisions. A completion report does not retroactively authorize changes outside the agreed scope.
