<?xml version="1.0" encoding="UTF-8"?>
<ModuleFile xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
    <UiMod name="MongbatPlayerStatusReactive" version="1.0">
        <Author name="Loop" />
		<Description text="https://github.com/loop-uc-ui/uus-corp-ui/" />
        <Dependencies>
            <Dependency name="Mongbat"/>
        </Dependencies>
        <Files>
            <File name="MongbatPlayerStatusReactiveMod.lua"/>
        </Files>

        <OnInitialize>
            <CallFunction name="Mongbat.ModManager.MongbatPlayerStatusReactive.OnInitialize"/>
        </OnInitialize>
    </UiMod>
</ModuleFile>
