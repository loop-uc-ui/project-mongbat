<?xml version="1.0" encoding="UTF-8"?>
<ModuleFile xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
	<UiMod name="MongbatHotbar" version="0.1" date="03/05/2026">

		<Author name="Loop" />
		<Description text="MongbatHotbar - reimplements the default HotbarSystem as a Mongbat mod" />

		<Dependencies>
			<Dependency name="Mongbat" />
		</Dependencies>

		<Files>
			<File name="MongbatHotbarMod.lua" />
		</Files>

		<OnInitialize>
			<CallFunction name="Mongbat.ModManager.MongbatHotbar.OnInitialize" />
		</OnInitialize>

		<OnShutdown>
			<CallFunction name="Mongbat.ModManager.MongbatHotbar.OnShutdown" />
		</OnShutdown>
	</UiMod>
</ModuleFile>
