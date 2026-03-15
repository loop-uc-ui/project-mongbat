## Mongbat Copilot Instructions

These are execution rules, not guidance. Follow them exactly.

## 0. Mission

Produce correct, minimal, evidence-based changes.
No speculative fixes.

## 1. Task Router (Required)

Before doing work, load the matching skill:

- bug/debug task -> .github/skills/bugfixing.md
- default window replacement task -> .github/skills/reimplementing-default-ui.md
- review task -> .github/skills/code-review.md

If no skill matches, use these rules directly.

## 2. Evidence Order (Required)

Trust sources in this order:

1. lua.log runtime errors
2. current repo code
3. default UI source
4. default UI docs

If docs conflict with source, source wins.

Default UI source:
https://github.com/loop-uc-ui/enhanced-client-default

Default UI docs:
https://loop-uc-ui.github.io/enhanced-client-default-docs/

## 3. Pre-Edit Gates (Hard Stop)

No code edits are allowed until all pass:

1. Failing path identified: exact file/function/line path to first failure.
2. Root cause identified: one concrete mismatch causing the observed error.
3. Fix class chosen: one smallest fix category from Section 4.
4. Architecture check: change respects child-owned events and existing framework boundaries.
5. Symmetry check: shutdown/reversal counterpart is identified.

If any gate fails, continue diagnosis and do not edit.

## 4. Fix Class Priority (Use Smallest)

1. Delete unnecessary broken logic.
2. Correct one incorrect call/value/condition.
3. Add one missing registration/wrapper.
4. Reorder a small local flow.
5. Add a new mechanism (only with explicit proof and justification).

## 5. Stop Conditions (Immediate)

Stop and return to diagnosis when any occur:

- first fix failed
- error changed unexpectedly
- crash appeared
- evidence no longer supports the active theory

Never do a second fix on the same failed theory.

## 6. Non-Negotiable Code Constraints

### 6.1 Lua Runtime

- no require/module
- no io/os/debug
- no goto
- use math.mod
- use wstring correctly
- define local functions before first call

### 6.2 Mod Namespace Discipline

In mod files, all engine interaction goes through Mongbat namespaces:

- Data
- Api
- Constants
- Components
- Utils

No raw engine globals in mod code.

### 6.3 Event and Data Discipline

- Child views own data/event handlers.
- Parents are layout and bubble targets where applicable.
- Do not invent broadcast systems.
- Treat data registration and callback registration as separate requirements.

### 6.4 XML/Lua Split

If callbacks fire but behavior is visually wrong, inspect XML creation-time attributes first.

## 7. Output Contracts

### 7.1 Bugfix Responses Must Include

1. failing path
2. root cause sentence
3. selected fix class
4. minimal diff summary
5. symmetry/regression check result

### 7.2 Review Responses Must Include

1. findings first, ordered by severity
2. evidence with file/line references per finding
3. open questions/assumptions
4. brief summary last

## 8. Quality Bar

- Prefer evidence over narrative.
- Prefer fewer changed lines.
- Prefer reversible changes.
- Keep docs aligned with behavior changes.
- Do not add debug print statements as a substitute for diagnosis.

## 9. Core Principle

Diagnosis -> decision -> minimal fix.
