<?xml version="1.0" encoding="UTF-8"?>
<ModuleFile xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
	<UiMod name="MongbatMobilesOnScreen" version="0.1" date="03/06/2026">

		<Author name="Loop" />
		<Description text="Mongbat MobilesOnScreen - reimplements the default MobilesOnScreen window" />

		<Dependencies>
			<Dependency name="Mongbat" />
		</Dependencies>

		<Files>
			<File name="MongbatMobilesOnScreenMod.lua" />
		</Files>

		<OnInitialize>
			<CallFunction name="Mongbat.ModManager.MongbatMobilesOnScreen.OnInitialize" />
		</OnInitialize>

		<OnShutdown>
			<CallFunction name="Mongbat.ModManager.MongbatMobilesOnScreen.OnShutdown" />
		</OnShutdown>
	</UiMod>
</ModuleFile>
