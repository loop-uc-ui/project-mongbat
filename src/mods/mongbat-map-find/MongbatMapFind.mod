<?xml version="1.0" encoding="UTF-8"?>
<ModuleFile xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
	<UiMod name="MongbatMapFind" version="0.1" date="08/17/2025">

		<Author name="Loop" />
		<Description text="Mongbat MapFind - replaces the default Map Find window" />

		<Dependencies>
			<Dependency name="Mongbat" />
		</Dependencies>

		<Files>
			<File name="MongbatMapFindMod.lua" />
		</Files>

		<OnInitialize>
			<CallFunction name="Mongbat.ModManager.MongbatMapFind.OnInitialize" />
		</OnInitialize>

		<OnShutdown>
			<CallFunction name="Mongbat.ModManager.MongbatMapFind.OnShutdown" />
		</OnShutdown>
	</UiMod>
</ModuleFile>
