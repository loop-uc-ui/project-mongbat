<?xml version="1.0" encoding="UTF-8"?>
<ModuleFile xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
	<UiMod name="MongbatActionsWindow" version="0.1" date="03/05/2026">

		<Author name="Loop" />
		<Description text="Mongbat Actions Window - reimplements the default ActionsWindow" />

		<Dependencies>
			<Dependency name="Mongbat" />
		</Dependencies>

		<Files>
			<File name="MongbatActionsWindowMod.lua" />
		</Files>

		<OnInitialize>
			<CallFunction name="Mongbat.ModManager.MongbatActionsWindow.OnInitialize" />
		</OnInitialize>

		<OnShutdown>
			<CallFunction name="Mongbat.ModManager.MongbatActionsWindow.OnShutdown" />
		</OnShutdown>
	</UiMod>
</ModuleFile>
