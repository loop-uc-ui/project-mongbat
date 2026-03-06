<?xml version="1.0" encoding="UTF-8"?>
<ModuleFile xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
	<UiMod name="MongbatResizeWindow" version="0.1" date="03/07/2023">

		<Author name="Loop" />
		<Description text="https://github.com/loop-uc-ui/project-mongbat/" />

		<Dependencies>
			<Dependency name="Mongbat" />
		</Dependencies>

		<Files>
			<File name="MongbatResizeWindowMod.lua" />
		</Files>

		<OnInitialize>
			<CallFunction name="Mongbat.ModManager.MongbatResizeWindow.OnInitialize" />
		</OnInitialize>

		<OnShutdown>
			<CallFunction name="Mongbat.ModManager.MongbatResizeWindow.OnShutdown" />
		</OnShutdown>
	</UiMod>
</ModuleFile>
