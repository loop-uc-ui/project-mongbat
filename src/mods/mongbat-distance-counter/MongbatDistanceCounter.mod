<?xml version="1.0" encoding="UTF-8"?>
<ModuleFile xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
	<UiMod name="MongbatDistanceCounter" version="0.1" date="03/07/2023">

		<Author name="Loop" />
		<Description text="https://github.com/loop-uc-ui/project-mongbat/" />

		<Dependencies>
			<Dependency name="Mongbat" />
		</Dependencies>

		<Files>
			<File name="MongbatDistanceCounterMod.lua" />
		</Files>

		<OnInitialize>
			<CallFunction name="Mongbat.ModManager.MongbatDistanceCounter.OnInitialize" />
		</OnInitialize>
		<OnShutdown>
			<CallFunction name="Mongbat.ModManager.MongbatDistanceCounter.OnShutdown" />
		</OnShutdown>
	</UiMod>
</ModuleFile>
