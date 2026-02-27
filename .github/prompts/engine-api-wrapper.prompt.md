# Engine API Wrapper

Generate a Mongbat `Api.*` wrapper for a raw UO Enhanced Client engine function.

## Instructions

Given one or more raw engine function names (e.g., `ButtonSetDisabledFlag`, `WindowSetTintColor`), generate the corresponding `Api.*` wrapper(s) following Mongbat conventions.

### Conventions

1. **Namespace**: Group under the appropriate `Api.*` sub-table. Determine the sub-table from the engine function prefix:
   - `Window*` → `Api.Window`
   - `Button*` → `Api.Button`
   - `Label*` / `LabelSet*` / `LabelGet*` → `Api.Label`
   - `DynamicImage*` → `Api.DynamicImage`
   - `CircleImage*` → `Api.CircleImage`
   - `TextEditBox*` → `Api.EditTextBox`
   - `StatusBar*` → `Api.StatusBar`
   - `LogDisplay*` → `Api.LogDisplay`
   - `ComboBox*` → `Api.ComboBox`
   - `ListBox*` → `Api.ListBox`
   - `AnimatedImage*` → `Api.AnimatedImage`
   - Other prefixes: create a new `Api.*` sub-table if needed.

2. **Naming**: Convert from engine naming to PascalCase method:
   - `ButtonSetDisabledFlag` → `Api.Button.SetDisabled`
   - `WindowGetShowing` → `Api.Window.IsShowing`
   - Strip the prefix, use `Is`/`Get`/`Set` verbs, drop redundant suffixes like `Flag`.

3. **Documentation**: Add `---@param` and `---@return` annotations matching the engine function's parameters, followed by a one-line `---` description. Look up the parameter types from the docs site or infer from the function name and usage in the default UI source.

4. **Template**:
```lua
---
--- {Description}.
---@param {paramName} {paramType} {Description}.
---@return {returnType} {Description}.
function Api.{Namespace}.{MethodName}({params})
    return {EngineFunction}({params})
end
```

5. **Placement**: Insert in alphabetical order within the appropriate `Api.*` section in `Mongbat.lua`.

### Research steps

If the function signature is unknown:
- Use `github_repo` on `loop-uc-ui/enhanced-client-default` to find usage examples.
- Use `fetch_webpage` on `https://loop-uc-ui.github.io/enhanced-client-default-docs/files/Source/MythicInterface-cpp.html` or `files/Source/Window-cpp.html` for documented signatures.
- Check existing `Api.*` wrappers in `Mongbat.lua` for the same namespace to match style.
