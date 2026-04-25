---
name: research-default-ui
description: "Use when you need to look up how the default UI handles something — e.g. how a global function is called, what arguments it takes, whether Unregister/Destroy is called on shutdown, how a window registers data. Covers fetching source from the remote repo, searching for function/global usage, and reading the local docs mirror."
---

# Research Default UI

## When to Use

- Verifying how an engine global is used before writing a Mongbat wrapper
- Checking whether a function is called at all (e.g. `UnregisterWindowData`)
- Understanding the Initialize/Shutdown lifecycle of a default-UI module
- Looking up argument shapes, event IDs, or WindowData key names
- Confirming correct behaviour before debugging unexpected engine behaviour

The golden rule: **never invent a mechanism the default UI doesn't use.**
Always verify against the source before deciding an approach is correct.

---

## What Works and What Doesn't

### GitHub code search — DOES NOT WORK
```
https://github.com/search?q=repo:loop-uc-ui/enhanced-client-default+<term>&type=code
```
This requires a GitHub sign-in. It will always return an auth wall. **Do not use it.**

### Raw file fetch — WORKS
Fetch individual files directly from `raw.githubusercontent.com`. Use `fetch_webpage` with the raw URL:

```
https://raw.githubusercontent.com/loop-uc-ui/enhanced-client-default/main/Source/<Filename>.lua
```

Examples:
- `https://raw.githubusercontent.com/loop-uc-ui/enhanced-client-default/main/Source/StatusWindow.lua`
- `https://raw.githubusercontent.com/loop-uc-ui/enhanced-client-default/main/Source/GenericGump.lua`
- `https://raw.githubusercontent.com/loop-uc-ui/enhanced-client-default/main/Source/ObjectHandle.lua`
- `https://raw.githubusercontent.com/loop-uc-ui/enhanced-client-default/main/Source/GumpsParsing.lua`

### Directory listing — WORKS
Browse via the GitHub tree URL to discover file names before fetching:
```
https://github.com/loop-uc-ui/enhanced-client-default/tree/main/Source
```
Use `fetch_webpage` on this URL. Returns the full flat file list.

---

## Repo Structure

All Lua source files are flat under `Source/`. A small number live under
`Source/Generic/`. When a file isn't found at a flat path, try
`Source/Generic/<Filename>.lua`.

Key files most relevant to Mongbat work:

| File | Contains |
|---|---|
| `StatusWindow.lua` | `RegisterWindowData`, `UnregisterWindowData`, window lifecycle pattern |
| `GenericGump.lua` | `GenericGump.OnShown` chain, gump lifecycle |
| `GumpsParsing.lua` | `GumpsParsing.MainParsingCheck`, suppress pattern |
| `ObjectHandle.lua` | `ObjectHandleWindow.CreateObjectHandles` pattern |
| `WindowUtils.lua` | `SaveWindowPosition`, `RestoreWindowPosition`, scale helpers |
| `InterfaceCore.lua`* | Core constants, `ButtonStates`, `scale` |
| `HotbarSystem.lua` | Hotbar slot/action registration |
| `ItemProperties.lua` | `SetActiveItem` shape |
| `EquipmentData.lua` | Paperdoll slot constants |

*`InterfaceCore` is declared in `InterfaceCore.txt` in the local `docs/` mirror.

---

## Local Docs Mirror

`docs/` contains files that are **not** in the `enhanced-client-default` repo.
They are hidden files embedded inside the UO Enhanced Client binary/installation
and extracted manually. They are the ground truth for engine-level APIs that
the default UI itself depends on but does not ship as source.

| File | Content |
|---|---|
| `docs/InterfaceCore.txt` | `InterfaceCore` module — ButtonStates, scale, etc. |
| `docs/Interface.xsd` | XML schema for window templates |
| `docs/UO_DefaultWindow.txt` | `UO_DefaultWindow` module source |
| `docs/UO_GenericGump.txt` | `UO_GenericGump` module source |
| `docs/UO_StandardDialog.txt` | Standard dialog helpers |
| `docs/singelinetextentry.txt` | Single-line text entry template |

**Check `docs/` first** for engine-level APIs — these files are not available
anywhere online. For default-UI Lua (windows, gumps, data handlers), fetch from
the network.

---

## Workflow

1. **Check `docs/` locally** — `grep_search` across `docs/**` for the symbol.
2. **Identify the file** — if not in docs, use the directory listing to find the right `.lua` file name.
3. **Fetch the raw file** — use `fetch_webpage` with the `raw.githubusercontent.com` URL.
4. **Search the fetched content** — look for the exact call site (Initialize, Shutdown, Update, etc.).
5. **Read call sites in context** — understand the full function, not just the line.

---

## Common Research Queries

### "Does the default UI call `X` at all?"
Fetch the most likely source file and search the result for the function name.

### "What arguments does engine global `Foo(...)` take?"
Find a call site in the default UI source — that is the ground truth.

### "How does the default UI handle `OnShutdown` for window Y?"
Fetch `Source/<WindowModule>.lua`, look at the `Shutdown` function.

### "What's the correct `RegisterWindowData` / `UnregisterWindowData` pattern?"
See `StatusWindow.lua`:
- `Initialize`: calls `RegisterWindowData(WindowData.X.Type, id)`
- `Shutdown`: calls `UnregisterWindowData(WindowData.X.Type, id)`
- Inside update handlers: sometimes calls Unregister+Register to switch the tracked ID

### "What events does `WindowRegisterEventHandler` use?"
The event value is always `WindowData.<Key>.Event` — fetch the source to confirm the exact key name.
