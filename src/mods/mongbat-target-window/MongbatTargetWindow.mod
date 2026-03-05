<?xml version="1.0" encoding="UTF-8"?>
<ModuleFile xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
	<UiMod name="MongbatTargetWindow" version="0.1" date="03/05/2026">

		<Author name="Loop" />
		<Description text="https://github.com/loop-uc-ui/project-mongbat/" />

		<Dependencies>
			<Dependency name="Mongbat" />
		</Dependencies>

		<Files>
			<File name="MongbatTargetWindowMod.lua" />
		</Files>

		<OnInitialize>
			<CallFunction name="Mongbat.ModManager.MongbatTargetWindow.OnInitialize" />
		</OnInitialize>

		<OnShutdown>
			<CallFunction name="Mongbat.ModManager.MongbatTargetWindow.OnShutdown" />
		</OnShutdown>
	</UiMod>
</ModuleFile>
