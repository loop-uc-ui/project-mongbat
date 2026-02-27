# Default UI Lookup

Research a vanilla UO Enhanced Client UI window or system to understand how it works before building or modifying a Mongbat mod that replaces it.

## Instructions

Given a window or system name (e.g., "StatusWindow", "MapWindow", "HealthBarManager"), perform these steps:

### 1. Search the default UI source

Use the `github_repo` tool to query `loop-uc-ui/enhanced-client-default` for the relevant Lua file(s). Key queries:

- The window name + "Initialize Shutdown" (e.g., `"StatusWindow Initialize Shutdown"`)
- Data types it registers (e.g., `"RegisterWindowData PlayerStatus"`)
- Event handlers it uses (e.g., `"WindowRegisterEventHandler StatusWindow"`)

### 2. Search the documentation

Use `fetch_webpage` on the relevant docs pages at `https://loop-uc-ui.github.io/enhanced-client-default-docs/`:

| Page | URL |
|---|---|
| Interface System (API) | `files/Source/MythicInterface-cpp.html` |
| Window (API) | `files/Source/Window-cpp.html` |
| Window Creation Basics | `files3/WindowCreationBasics-txt.html` |
| Anchoring | `files3/Anchoring-txt.html` |

**Note:** The docs are outdated. If a doc example contradicts the repo code, the repo is correct.

### 3. Summarize findings

Report back with:

- **Lifecycle**: How the window initializes and shuts down (global table pattern, `Initialize`/`Shutdown` functions).
- **Data sources**: Which `WindowData.*` types it registers and reads from.
- **Events**: Which system events, data events, and core events it handles.
- **Key functions**: Important callbacks and their signatures.
- **XML structure**: The window's XML definition if relevant (template name, child elements).
- **Mongbat mapping**: How this maps to Mongbat's component system — which `Components.*` factory, which `Constants.DataEvents`, which `DefaultComponent` proxy would be used.

### 4. Check existing mods

Search `src/mods/` for any existing Mongbat mod that already wraps this window. If found, note how it uses the `DefaultComponent` system to disable the vanilla version.
