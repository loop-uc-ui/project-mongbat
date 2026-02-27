# New Mongbat Mod

Generate the boilerplate files for a new Mongbat mod.

## Instructions

Ask for the mod name if not provided (e.g., "MyFeature"). Then generate two files:

### 1. `.mod` file

Place at `src/mods/mongbat-{kebab-name}/{PascalName}.mod`.

Use this template, replacing placeholders:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<ModuleFile xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
	<UiMod name="{PascalName}" version="0.1" date="{MM/DD/YYYY}">

		<Author name="" />
		<Description text="" />

		<Dependencies>
			<Dependency name="Mongbat" />
		</Dependencies>

		<Files>
			<File name="{PascalName}Mod.lua" />
		</Files>

		<OnInitialize>
			<CallFunction name="Mongbat.ModManager.{PascalName}.OnInitialize" />
		</OnInitialize>

		<OnShutdown>
			<CallFunction name="Mongbat.ModManager.{PascalName}.OnShutdown" />
		</OnShutdown>
	</UiMod>
</ModuleFile>
```

- `{PascalName}` is the mod name prefixed with `Mongbat`, e.g., `MongbatMyFeature`.
- `{kebab-name}` is the lowercase-hyphenated form, e.g., `mongbat-my-feature`.
- `{MM/DD/YYYY}` is today's date.

### 2. `.lua` file

Place at `src/mods/mongbat-{kebab-name}/{PascalName}Mod.lua`.

Use this template:

```lua
local NAME = "{PascalName}Window"

---@param context Context
local function OnInitialize(context)
    local function Window()
        return context.Components.Window {
            Name = NAME,
            OnInitialize = function(self)
                self:setDimensions(300, 200)
            end,
        }
    end

    Window():create(true)
end

---@param context Context
local function OnShutdown(context)
    context.Api.Window.Destroy(NAME)
end

Mongbat.Mod {
    Name = "{PascalName}",
    Path = "/src/mods/mongbat-{kebab-name}",
    OnInitialize = OnInitialize,
    OnShutdown = OnShutdown
}
```

### Naming rules

- The `Name` field in `Mongbat.Mod` and the `.mod` file must match exactly.
- The `Path` must match the folder under `src/mods/`.
- The `CallFunction` names must follow the pattern `Mongbat.ModManager.{PascalName}.OnInitialize` / `.OnShutdown`.
- Window names should be prefixed with the mod's PascalName to avoid collisions with other mods and vanilla windows.
