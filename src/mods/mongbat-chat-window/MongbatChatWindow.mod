<?xml version="1.0" encoding="UTF-8"?>
<ModuleFile xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
	<UiMod name="MongbatChatWindow" version="0.1" date="03/05/2026">

		<Author name="Loop" />
		<Description text="Mongbat Chat Window - reimplements the default chat system" />

		<Dependencies>
			<Dependency name="Mongbat" />
		</Dependencies>

		<Files>
			<File name="MongbatChatWindowMod.lua" />
		</Files>

		<OnInitialize>
			<CallFunction name="Mongbat.ModManager.MongbatChatWindow.OnInitialize" />
		</OnInitialize>

		<OnShutdown>
			<CallFunction name="Mongbat.ModManager.MongbatChatWindow.OnShutdown" />
		</OnShutdown>
	</UiMod>
</ModuleFile>
