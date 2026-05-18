<?xml version="1.0" encoding="UTF-8"?>
<ModuleFile xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
	<UiMod name="Mongbat" version="0.1" date="08/17/2025">

		<Author name="Loop" />
		<Description text="https://github.com/loop-uc-ui/project-mongbat/"/>

		<Dependencies>
			<Dependency name="MongbatInternal" />
			<Dependency name="MongbatUtils" />
			<Dependency name="MongbatConstants" />
			<Dependency name="MongbatApi" />
			<Dependency name="MongbatData" />
			<Dependency name="MongbatDebugger" />
			<Dependency name="MongbatUI" />
			<Dependency name="MongbatSystems" />
		</Dependencies>

		<Files>
            <File name="Mongbat.lua"/>
		</Files>

		<OnInitialize>
			<CallFunction name="_Mongbat.OnInitialize"/>
		</OnInitialize>

        <OnUpdate>
			<CallFunction name="_Mongbat.OnUpdate"/>
		</OnUpdate>

		<OnShutdown>
			<CallFunction name="_Mongbat.OnShutdown"/>
		</OnShutdown>
	</UiMod>
</ModuleFile>
