<?xml version="1.0" encoding="UTF-8"?>
<ModuleFile xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
	<UiMod name="MongbatCrystalPortal" version="0.1" date="03/06/2026">

		<Author name="Loop" />
		<Description text="https://github.com/loop-uc-ui/uus-corp-ui/" />

		<Dependencies>
			<Dependency name="Mongbat" />
		</Dependencies>

		<Files>
			<File name="MongbatCrystalPortalMod.lua" />
		</Files>

		<OnInitialize>
			<CallFunction name="Mongbat.ModManager.MongbatCrystalPortal.OnInitialize" />
		</OnInitialize>
		<OnShutdown>
			<CallFunction name="Mongbat.ModManager.MongbatCrystalPortal.OnShutdown" />
		</OnShutdown>
	</UiMod>
</ModuleFile>
