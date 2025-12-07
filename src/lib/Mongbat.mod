<?xml version="1.0" encoding="UTF-8"?>
<ModuleFile xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
	<UiMod name="Mongbat" version="0.1" date="08/17/2025">

		<Author name="Loop" />
		<Description text="https://github.com/loop-uc-ui/project-mongbat/"/>

		<Files>
            <File name="Mongbat.lua"/>
		</Files>

		<OnInitialize>
			<CallFunction name="_Mongbat.OnInitialize"/>
		</OnInitialize>

		<OnShutdown>
			<CallFunction name="_Mongbat.OnShutdown"/>
		</OnShutdown>
	</UiMod>
</ModuleFile>
