<?xml version="1.0" encoding="UTF-8"?>
<ModuleFile xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
	<UiMod name="MongbatTipOfTheDay" version="0.1" date="03/06/2026">

		<Author name="Loop" />
		<Description text="https://github.com/loop-uc-ui/project-mongbat/" />

		<Dependencies>
			<Dependency name="Mongbat" />
		</Dependencies>

		<Files>
			<File name="MongbatTipOfTheDayMod.lua" />
		</Files>

		<OnInitialize>
			<CallFunction name="Mongbat.ModManager.MongbatTipOfTheDay.OnInitialize" />
		</OnInitialize>
		<OnShutdown>
			<CallFunction name="Mongbat.ModManager.MongbatTipOfTheDay.OnShutdown" />
		</OnShutdown>
	</UiMod>
</ModuleFile>
