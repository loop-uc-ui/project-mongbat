# Mongbat

Extensible Lua framework for replacing and extending Ultima Online Enhanced Client UI windows.

## What This Project Is

Mongbat wraps the UO Enhanced Client Lua/XML UI runtime with:

- Component factories (Window, Scaffold, Label, StatusBar, ScrollWindow, etc.)
- Namespace wrappers for engine functions and runtime data (Api, Data, Constants, Utils)
- Child-centric event dispatch using a framework cache
- Default window suppression and restoration via DefaultComponent

Core files:

- src/lib/Mongbat.lua
- src/lib/Mongbat.xml

Mods live under src/mods/<mod-name>/.

## Project Structure

```text
src/
   lib/
      Mongbat.lua
      Mongbat.xml
      Mongbat.mod
   mods/
      mongbat-*/
docs/
Fonts/
types/
```

## Architecture Essentials

### 1) Child-Centric Event Dispatch

Every component registers events under its own window name. Dispatch looks up the active window in Cache and invokes that view.

Implication:

- Data handlers belong on the child that renders the data.
- Parent windows are layout containers, not event relays.

### 2) Data Registration Is Not Event Registration

- RegisterWindowData(dataType, id) loads data into WindowData.
- WindowRegisterEventHandler(windowName, eventId, callback) routes callbacks.

Both are required for entity-specific updates.

### 3) XML + Lua Two-Layer System

Lua controls runtime state. XML defines creation-time behavior. If visual behavior is wrong and events fire, compare XML attributes first.

### 4) DefaultComponent Is In-Place Mutation

disable() replaces original table functions with no-ops.
restore() restores saved functions.
It does not stop engine-side XML creation by itself.

## Namespaces

Mongbat exposes engine interaction through these namespaces:

- Data: reads from SystemData / WindowData wrappers
- Api: engine actions
- Constants: IDs and enums
- Components: UI factories and defaults
- Utils: general array/table/string operations

## Developer Guide

Detailed implementation guidance is in docs/Developer-Guide.md.

## External References

- Default UI source: https://github.com/loop-uc-ui/enhanced-client-default
- Default UI docs: https://loop-uc-ui.github.io/enhanced-client-default-docs/
- Official game site: https://uo.com/
