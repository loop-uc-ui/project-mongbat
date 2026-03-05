<?xml version="1.0" encoding="UTF-8"?>
<ModuleFile xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
	<UiMod name="MongbatMobileHealthBar" version="0.1" date="03/05/2026">

		<Author name="Loop" />
		<Description text="https://github.com/loop-uc-ui/project-mongbat/" />

		<Dependencies>
			<Dependency name="Mongbat" />
		</Dependencies>

		<Files>
			<File name="MongbatMobileHealthBarMod.lua" />
		</Files>

		<OnInitialize>
			<CallFunction name="Mongbat.ModManager.MongbatMobileHealthBar.OnInitialize" />
		</OnInitialize>

		<OnShutdown>
			<CallFunction name="Mongbat.ModManager.MongbatMobileHealthBar.OnShutdown" />
		</OnShutdown>
	</UiMod>
</ModuleFile>
