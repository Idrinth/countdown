<?xml version="1.0" encoding="UTF-8"?>
<ModuleFile xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
	<UiMod name="Countdown" version="1.0.0" date="2021-03-21" >
    <VersionSettings gameVersion="1.4.8" windowsVersion="1.40" savedVariablesVersion="1.50" />

		<Author name="Idrinth"/>

		<Description text="Provides a countdown for scenario end and start as well as one on demand" />
		<Dependencies>
			<Dependency name="EA_ObjectiveTrackers" />
			<Dependency name="LibSlash" optional="true" />
		</Dependencies>
		<Files>
			<File name="window.xml" />
            <File name="countdown.lua" />
		</Files>
		<OnInitialize>
            <CallFunction name="Countdown.OnInitialize" />
		</OnInitialize>
		<SavedVariables>
			<SavedVariable name="Countdown.Settings"/>
		</SavedVariables>
		<OnUpdate>
		   <CallFunction name="Countdown.OnUpdate" />
		</OnUpdate>
		<OnShutdown/>
		<WARInfo>
			<Categories>
				<Category name="RVR"/>
			</Categories>
		</WARInfo>

	</UiMod>
</ModuleFile>
