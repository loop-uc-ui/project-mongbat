---
name: debugger
description: 'Debug runtime errors in Mongbat mods. USE WHEN: the user shares a log error, a window fails silently, a feature does not appear, or the game crashes (stack overflow).'
---

# Debugger

## Error Log

Runtime errors are written to the log file declared in `.env`:

```
C:\Program Files (x86)\Electronic Arts\Ultima Online Enhanced\logs\lua.log
```

The user may paste log errors directly. Log entries include the file, line number, and error message. Start there.

## Error Types

**Logged errors** — Most runtime exceptions do not crash the client. They appear as error lines in the log (e.g. `attempt to call a nil value`, `attempt to index a nil value`). The window or feature simply stops working.

**Silent failures** — Some things fail without producing any log entry. If a window doesn't appear, a binding doesn't fire, or a value doesn't update, there may be no error at all. Common causes:
- Wrong event kind (`core` vs `data` vs `system`)
- Missing `RegisterData` for entity-scoped data events
- Template name mismatch between XML and Lua
- Window created but not shown
- Binding assigned before `onInitialize` runs

**Crashes (stack overflow)** — If the client crashes entirely, it is almost always a stack overflow. Look for circular calls: an event handler that triggers the same event, a property setter that re-enters itself, or broadcast dispatch loops.

## Debugging Approach

1. Read the error message and line number first.
2. Trace the exact code path — don't guess.
3. Compare with how the default UI handles the same thing.
4. If one fix doesn't work, stop and reassess. Don't iterate on a broken theory.
