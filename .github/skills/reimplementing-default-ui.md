# Skill: Reimplementing a Default UO UI Window in Mongbat

Use this when replacing a vanilla EC window with a Mongbat mod.

## Goal

Match default behavior with simpler architecture, not invented behavior.

## Required Pre-Build Gates

No implementation until all pass:

1. Baseline Lua and XML for target window collected.
2. Recreation/suppression inventory completed.
3. Behavior inventory completed.
4. Mongbat capability mapping completed.
5. Symmetry plan written (init action -> shutdown reverse).

If any gate fails, continue research and do not write code.

## Phase 1: Baseline Research (Required)

Do not write code in this phase.

### 1.1 Gather Source of Truth

From loop-uc-ui/enhanced-client-default, retrieve:

- target window Lua file
- target window XML file
- all direct creation call sites
- periodic check functions in Interface.lua

### 1.2 Build Behavior Inventory

Document:

- data tables used
- registration timing and id model
- event handlers used
- interaction behavior (click, dbl-click, right-click, drag, tooltip, targeting)
- shutdown cleanup behavior

### 1.3 Build Suppression Inventory

Document every mechanism that can recreate the default window:

- explicit CreateWindow calls
- UserAction triggers
- Interface periodic checks
- open-state flags

Do not proceed if any recreation vector is still unknown.

## Phase 2: Framework Capability Map

For each needed behavior, map to Mongbat:

- DataEvent constant
- Data wrapper
- EventHandler route
- View callback method
- model annotation
- Component/DefaultComponent wrapper

If missing, add the smallest framework addition first.

## Phase 3: Implementation Plan

Plan in five blocks:

1. suppress default safely
2. create replacement window tree
3. bind data via setId on consuming child views
4. implement interactions by mirroring default semantics
5. restore symmetry on shutdown

## Phase 4: Build

### 4.1 Suppress Default

At minimum:

- default:disable()
- neutralize recreation flags/check paths as needed
- destroy existing default instance if present

### 4.2 Create Replacement

- top-level scaffold/window
- child components and layout
- event handlers via model keys

### 4.3 Bind Data Correctly

- call setId(entityId) on child that consumes entity-specific data
- avoid manual registration in mod unless unavoidable

### 4.4 Interaction Parity

Mirror default UI intent, including:

- tooltips and active item behavior
- drag/drop semantics
- context menus
- targeting mode paths

## Phase 5: Shutdown Symmetry

For every init action, define exact reverse action.

Required:

- destroy replacement windows
- restore default component
- restore flags/check state

## Completion Output Contract

Report must include:

1. Baseline files used (Lua + XML).
2. Suppression vectors handled.
3. Data-binding ownership (which child calls setId and why).
4. Interaction parity checklist result.
5. Symmetry checklist result.
6. Known deviations (if any).

## Verification Checklist

- default window never ghost-reappears during mod runtime
- all expected data updates arrive
- all baseline interactions match default behavior
- no raw engine global usage in mod file
- no extra speculative mechanisms introduced

## Anti-Patterns to Avoid

- relying on disable() alone for suppression
- calling UserAction that re-creates the default window unintentionally
- binding data to parent container instead of consuming child
- guessing XML attributes instead of checking default template
- adding complexity after one failed fix instead of re-diagnosing

## Completion Criteria

Task is complete only when:

- behavior parity is verified
- suppression is stable
- lifecycle symmetry is clean
- framework/docs reflect any new reusable patterns
- completion output contract is satisfied
