# Skill: Mongbat Bugfixing Protocol

Use this for any debugging or bugfix task.
This protocol is mandatory, sequential, and gate-based.

## Objective

Arrive at one well-supported root cause, then apply one minimal fix.

## Required Artifacts (Before Any Edit)

All four must exist before code changes:

1. First failing log entry from lua.log.
2. Exact call path to first failure (entry -> throw point).
3. One-sentence root cause.
4. Selected fix category (see Phase 3).

If any artifact is missing, stop and continue diagnosis.

## Phase 1: Collect Facts (No Code Changes)

### 1.1 Read the Runtime Log First

1. Open .env and get loglocation.
2. Read lua.log.
3. Extract only [Error] entries first.

Capture:

- failing function name
- window names involved
- template names involved
- first error and cascade errors separately

### 1.2 Build an Error Timeline

Write a short timeline:

1. first failing line
2. immediate consequence
3. downstream noise

Do not fix downstream noise first.

### 1.3 Trace the Exact Call Path

Trace from entry to throw point.
State:

- entry function
- each key call in order
- first unsafe assumption

If you cannot point to a concrete line, diagnosis is incomplete.

### 1.4 Compare with Default UI

Fetch both files from default UI for equivalent window/component:

- Lua behavior file
- XML template file

Compare:

- registration calls
- argument values
- initialization order
- XML attributes

If parity comparison is incomplete, diagnosis is incomplete.

## Phase 2: Root Cause Statement

Write one sentence in this form:

Root cause: <specific code path> fails because <concrete mismatch>, which causes <observed error>.

Bad root cause examples:

- maybe timing issue
- likely event dispatch issue
- might be race condition

Good root cause examples:

- View:onInitialize throws in model OnInitialize before child creation loop runs, causing child windows to never exist.
- Template attribute movable is missing in XML, so drag behavior never activates regardless of Lua handlers.

Only one root cause is allowed per fix.

## Phase 3: Choose Fix Category

Pick the smallest valid category:

1. Delete broken/unneeded logic
2. Correct one bad call/value
3. Add one missing registration
4. Small local reorder
5. New mechanism (requires explicit justification)

If category 5, pause and justify before implementation.

## Phase 4: Implement Minimally

Rules:

- change only lines needed for proven root cause
- no opportunistic cleanup
- no speculative booleans/flags
- no debug print scaffolding
- no second speculative change in the same pass

## Phase 5: Verify

### 5.1 Symmetry Check

For each init action, confirm shutdown counterpart.

### 5.2 Regression Check

Verify related event/data paths still align with architecture.

### 5.3 Documentation Check

If behavior contract changed, update:

- README.md
- .github/copilot-instructions.md
- relevant skill files

### 5.4 Completion Output Contract

Report must include:

1. Failing path: <entry -> throw line>
2. Root cause: <single sentence>
3. Fix category: <1-5>
4. Changed lines summary: <what changed and why minimal>
5. Symmetry check: <pass/fail + note>
6. Regression risks: <short list or none>

## Failed Fix Rule

If the first fix fails:

1. stop
2. re-read new error
3. re-run Phase 1 from scratch

No second fix on the same theory.

## Fast Triage Table

| Symptom | Primary Check |
|---|---|
| Window X does not exist | Upstream init failure before creation |
| Unable to create from template | XML not loaded / wrong template name |
| Click handlers not firing | Core event registration and Cache lookup |
| Data not updating | setId/data registration on correct child |
| Visual wrong but callbacks fire | XML creation-time attribute mismatch |
| Stack overflow | re-entrant dispatch or recursion loop |

## Completion Criteria

Bugfix is complete only when all are true:

- root cause sentence is concrete
- fix category is minimal
- symmetry is preserved
- no speculative mechanisms added
- completion output contract is satisfied
