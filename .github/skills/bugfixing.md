# Skill: Debugging and Fixing Bugs in Mongbat

This is a **mandatory step-by-step procedure** for diagnosing and fixing any bug in the Mongbat framework or its mods. Follow every step in order. **Do not write or change ANY code until Phase 2 is complete.** The history of this project proves that skipping diagnosis and jumping to code changes wastes enormous effort and money.

---

## Ground Rules

These rules are non-negotiable. They exist because every one of them was violated in the past, causing crashes, wasted tokens, and user frustration.

1. **ONE fix attempt per theory.** If a fix doesn't work, do not iterate on it. Go back to Phase 1.
2. **Removal before addition.** When framework code causes problems, first ask: "do we need this at all?" Deleting broken code is a valid fix. It is often THE fix.
3. **Never layer complexity on complexity.** If the existing pattern is simple and the proposed fix is complex, the fix is almost certainly wrong. The Mongbat codebase follows simple patterns. A correct fix fits those patterns.
4. **Never contradict the existing architecture.** If the framework dispatches events via `withActiveView`, do not invent a broadcast mechanism. If the engine delivers data events asynchronously, do not force-fire them synchronously. Work WITH the existing design.
5. **Trust the engine's event delivery.** If data isn't arriving, the problem is registration or dispatch routing — not timing. Do not add synthetic event firing, polling loops, or "initial data" mechanisms.
6. **Present findings before coding.** After Phase 1, summarize what you found in 3-5 sentences. State your proposed fix. Wait for user confirmation if the fix is non-trivial or touches framework internals. If the fix is a simple removal or one-line change, proceed.

---

## Phase 1: Diagnose (NO CODE CHANGES)

### Step 1.1 — Read the Error

Read the error message. This is the ONLY source of truth. Not your theory, not your intuition — the error.

- **If the user provides a screenshot or log output**, read every line. Extract:
  - Which window names appear (random strings = auto-generated child names)
  - Which engine functions failed (`WindowGetDimensions`, `WindowSetDimensions`, `WindowAddAnchor`, etc.)
  - The exact error pattern (e.g., "Window X does not exist" = X was never created)
  - Which mod name appears in parentheses (e.g., `(MongbatPlayerStatus)`)

- **If `lua.log` is available** (path from `.env`), read it. Search for `[Error]` entries.

- **Common error cascades to recognize immediately:**
  - `"Window <randomName> does not exist"` for multiple random names → **children were never created**. The parent's `onInitialize` threw an exception before reaching the child-creation loop. Find what threw.
  - `"Unable to create window: X, from template Y"` → XML template Y wasn't loaded. Check `.mod` file dependencies and XML file paths.
  - `"Script Call failed - No Lua State"` → benign shutdown noise. Ignore.
  - `"attempt to index global 'Mongbat' (a nil value)"` → Mongbat.lua failed to load. Check for UTF-8 BOM or syntax error.

### Step 1.2 — Trace the Code Path

Starting from the error, trace backwards through the code to find the root cause. Read the actual code — do not guess.

1. **Identify the entry point.** Which function was executing when the error occurred? (e.g., `Window:onInitialize`, `View:onInitialize`, `StatusBar:onInitialize`, a model's `OnInitialize` callback)
2. **Read that function line by line.** What runs before the failing line? What runs after it? If an exception at line N prevents lines N+1 through end from executing, what are those lines?
3. **Check the call chain.** If `Window:onInitialize` calls `View.onInitialize(self)`, and `View:onInitialize` calls `self._model.OnInitialize(self)`, and the model's `OnInitialize` sets bindings that trigger a data handler that throws — the root cause is in the data handler, but the SYMPTOM is "children not created" because the child-creation loop comes after `View.onInitialize` in `Window:onInitialize`.

**Critical principle:** Exceptions in Lua are NOT caught unless explicitly wrapped in `pcall`. An uncaught exception in `View:onInitialize` will abort the entire `Window:onInitialize` call, including all subsequent child creation.

### Step 1.3 — Compare to the Default UI

If the bug involves a component type that exists in the default UI:

1. Search `loop-uc-ui/enhanced-client-default` for both the **Lua AND XML** files.
2. Compare how the default UI registers data, creates windows, and handles events.
3. Note concrete differences — not abstract theories. "The default UI calls X with argument Y; we call X with argument Z" is useful. "Maybe the engine doesn't support this" is not.

### Step 1.4 — Identify the Root Cause

By now you should have ONE specific root cause. State it as a concrete fact:

- "The `_notifyBindings` call in `View:onInitialize` invokes `onUpdatePlayerStatus` before children exist, throwing an exception that aborts `Window:onInitialize` before the child-creation loop."
- "The `withMouseOverView` dispatcher uses `MouseOverWindow.name` which returns sub-element names not in Cache, so the lookup fails and the handler is never called."
- "`mergeProperties(NewClass)` was not added, so property access returns nil and crashes `wrapChildForParent`."

If you cannot state the root cause as a concrete fact with a specific line of code, **you are not done diagnosing**. Go back to Step 1.2.

---

## Phase 2: Plan the Fix

### Step 2.1 — Choose the Simplest Fix

Rank these fix categories from most to least preferred:

1. **Delete the broken code.** If the code isn't needed, remove it. (e.g., `_notifyBindings` was removed entirely — 15 lines deleted, bug fixed.)
2. **Fix the specific broken line.** Change one value, one argument, one condition. (e.g., change `withMouseOverView` back to `withActiveView` — one function reference changed.)
3. **Add a missing piece.** If something was forgotten (e.g., `mergeProperties` call), add just that. One line.
4. **Restructure a small section.** If the code path is wrong, rearrange it. Move the child-creation loop, reorder init steps, etc.
5. **Add new framework code.** LAST RESORT. Only if the framework genuinely lacks a capability that the default UI has. This requires understanding both the framework and the default UI deeply.

**If your proposed fix is category 5, stop and present it to the user before proceeding.**

### Step 2.2 — Verify the Fix Doesn't Contradict Existing Patterns

Before writing code, check:

- Does this fix work WITH the existing dispatch model (`withActiveView`, `Cache` lookup, per-view event registration)?
- Does this fix work WITH the existing initialization order (`View:onInitialize` → model `OnInitialize` → child creation)?
- Does this fix introduce any new concepts (new tables, new dispatch mechanisms, new lifecycle hooks)? If yes, is that truly necessary, or can the existing mechanisms handle it?
- Have similar fixes been tried AND FAILED before? Check the anti-patterns memory.

### Step 2.3 — Check the Anti-Pattern List

Before implementing, verify your fix does NOT match any of these known-bad patterns:

| Anti-Pattern | What Happened | Why It Failed |
|---|---|---|
| Broadcasting events to all Cache entries | `broadcastToBindings` iterated all views on each data event | Stack overflow from re-entrant event dispatch |
| Force-firing events during init | `_notifyBindings` called handlers before engine data was ready | Exceptions aborted init, preventing child creation |
| Using `withMouseOverView` for CoreEvents | Changed `OnLButtonUp` dispatcher | `MouseOverWindow.name` returns sub-element names not in Cache |
| Adding `mergeProperties` out of order | New class properties returned nil | Cascading failures in `wrapChildForParent` |
| Guessing at XML attributes | Assumed Lua could configure everything | Many behaviors are XML-only; no Lua setter exists |
| Multiple speculative fixes without diagnosis | Layered broadcast on top of force-fire on top of guard clauses | Each layer hid the real problem and added new failure modes |

---

## Phase 3: Implement

### Step 3.1 — Make the Minimal Change

Implement exactly what you planned in Phase 2. Nothing more.

- Do not "clean up" surrounding code.
- Do not add error handling "just in case."
- Do not refactor adjacent functions.
- Do not add debug print statements.

### Step 3.2 — Verify Symmetry

If the fix touches initialization, verify shutdown still reverses it. If the fix adds registration, verify unregistration exists. Check the `onShutdown` counterpart of any `onInitialize` change.

### Step 3.3 — Update Documentation

If the fix changes framework behavior that is documented in:
- `.github/copilot-instructions.md`
- `.github/skills/*.md`
- `README.md`

Update those documents. Remove references to deleted concepts. Do not leave stale documentation that describes code that no longer exists.

---

## Phase 4: If the Fix Doesn't Work

**STOP. Do not attempt a second fix on the same theory.**

1. Re-read the error output after your fix.
2. Is it the SAME error? → Your fix didn't address the root cause. Go back to Phase 1, Step 1.2.
3. Is it a DIFFERENT error? → Your fix may have been partially correct but exposed a second issue. Diagnose the new error from scratch (Phase 1).
4. Is it a CRASH? → Your fix introduced a worse problem. **Revert immediately.** Then go back to Phase 1.

**The maximum number of fix attempts before asking the user is TWO.** If two fixes fail, present your findings:
- "Here is the error. Here is what I traced. Here is what I tried and why it didn't work. Here is what I think the remaining possibilities are."

Let the user guide the next step. They know the runtime behavior; you know the code. Combine both.

---

## Quick Reference: Common Root Causes

| Symptom | Likely Root Cause | Fix |
|---|---|---|
| "Window <random> does not exist" (multiple) | Exception in `onInitialize` before child-creation loop | Find and fix the throwing code, or remove it |
| Component renders but no data | Event handler not registered, or registered on wrong window | Check `bindings` assignment and `setId()` call |
| Click events don't fire | Wrong dispatcher function, or `Cache` lookup fails | Verify `withActiveView` for CoreEvents, check window name in Cache |
| Stack overflow / crash | Re-entrant event dispatch, infinite recursion | Remove the re-entrant call; never iterate Cache during event dispatch |
| "attempt to index nil value" on property | Missing `mergeProperties(Class)` call | Add the call at end of Mongbat.lua, in parent-before-child order |
| XML template not found | `.mod` file missing dependency or XML file not listed | Check `.mod` XML for `<Dependency>` and `<File>` entries |
| `'Mongbat' is a nil value` in mod | Mongbat.lua failed to parse | Check for UTF-8 BOM or Lua syntax error |
| Visual wrong despite correct Lua | Missing XML attribute with no Lua setter | Fetch default UI XML, compare attributes, create custom template |
