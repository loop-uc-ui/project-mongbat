---
name: code-research
description: 'Research UO Enhanced Client engine behavior and default UI patterns. USE WHEN: needing to understand how the engine handles a specific feature, looking up default UI implementation details, or investigating how stock windows/events work before implementing a Mongbat wrapper.'
---

# Code Research

Mongbat is a wrapper around the Enhanced Client's default UI. When you need to understand engine fundamentals or default behavior, consult the default UI's source code and documentation.

First look in the workspace for enhanced-client-default and enhanced-client-default-docs. If that fails, they may be viewed
externally here:

- **Documentation**: https://loop-uc-ui.github.io/enhanced-client-default-docs/files3/Introduction-txt.html
- **Default UI source**: https://github.com/loop-uc-ui/enhanced-client-default

## When to Research

- Before inventing a mechanism, search the default UI for how it handles the same thing.
- When an engine API behaves unexpectedly, compare with how the default UI calls it.
- When wrapping a new default window, read its source to understand initialization order, data registrations, and shutdown cleanup.
