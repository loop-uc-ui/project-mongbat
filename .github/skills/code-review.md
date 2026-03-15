# Skill: Mongbat Code Review Protocol

Use this for PR or patch review requests.
Focus on defects and regressions first, not style.

## Review Output Contract

Output in this order:

1. findings by severity
2. open questions/assumptions
3. short summary

If no findings, say so explicitly and list remaining testing gaps.

Do not include praise or broad narrative before findings.

## Severity Model

- Critical: crash, data corruption, infinite recursion, unrecoverable UI failure
- High: wrong behavior likely in normal use, lifecycle leaks, broken suppression/restore
- Medium: architecture drift, maintainability risk, incomplete symmetry
- Low: clarity/docs/test coverage gaps

## Mandatory Checklist

### 1) Engine Access Discipline

- No raw engine globals in mod code.
- All engine access routes through Api/Data/Constants/Components/Utils.

### 2) Event Architecture

- No manual event registration in mods unless explicitly justified.
- Data handlers attached to child views that consume the data.
- Correct event category usage (Core vs System vs Data).

### 3) Lifecycle Symmetry

Check each initialize action has shutdown reversal:

- disable <-> restore
- create <-> destroy
- register <-> unregister
- set flag <-> reset flag

### 4) Default Window Replacement Safety

If replacing default UI:

- uses Components.Defaults
- disables on init
- restores on shutdown
- handles recreation flags if applicable
- destroys pre-existing engine window if needed

### 5) XML/Lua Coherence

If visual or interaction behavior changed:

- verify template attributes exist and match intent
- ensure Lua change is not trying to replace XML-only behavior

### 6) Lua Compatibility

- no require/module/goto/io/os/debug
- uses wstring appropriately
- local function declaration order is safe

### 7) Utility and Abstraction Hygiene

- no repeated inline patterns that should be framework-level
- no redundant guard clauses if framework already guards
- no speculative flags introduced without evidence

### 8) Type and Annotation Quality

- non-obvious params/returns are annotated
- complex model/data shapes are documented

### 9) Acceptance Criteria Coverage

Map each issue requirement to concrete code path and mark pass/fail.

## Reporting Template

Use this exact structure:

## Review Findings

1. [Severity] <title>
   - Evidence: <file + line>
   - Impact: <runtime consequence>
   - Fix direction: <smallest corrective action>

## Open Questions

1. <question>

## Summary

<one short paragraph>

## Residual Testing Gaps

1. <gap>

## Minimum Evidence Rule

Every finding must cite concrete evidence in repo code.
If evidence is insufficient, move it to Open Questions instead of Findings.
