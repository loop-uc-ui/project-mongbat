# Developer Guide

This guide contains implementation-focused details that are intentionally kept out of the top-level README.

## Lua Runtime Constraints

- Lua 5.0/5.1 style environment
- no require/module
- no io/os/debug
- no goto
- math.mod (not math.fmod)
- wstring support (L"text", towstring, StringToWString)
- local functions must be defined before first call site

## Typical Mod Lifecycle

1. OnInitialize creates the replacement or extension views.
2. Runtime events and data updates drive UI behavior.
3. OnShutdown destroys created views and restores replaced defaults.
