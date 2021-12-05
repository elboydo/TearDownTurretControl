#include "controls.lua"


changingKey = false
selectedKey = ""

-- esc	Escape key
-- lmb	Left mouse button
-- rmb	Right mouse button
-- up	Up key
-- down	Down key
-- left	Left key
-- right	Right key
-- space	Space bar
-- interact	Interact key
-- return	Return key
-- any	Any key or button
-- a,b,c,...	Latin, alphabetical keys a through z
-- mousewheel	Mouse wheel. Only valid in InputValue.
-- mousedx	Mouse horizontal diff. Only valid in InputValue.
-- mousedy
uniqueCharacters = {
	[1] = "lmb",
	[2] = "rmb",
	[3] = "up",
	[4] = "down",
	[5] = "left",
	[6] = "right",
	[7] = "space",
	[8] = "interact",
	[9] = "return",

}

-- The_Letter = ('ABCDEFGHIJKLMNOPQRSTUVWXYZA'):match(The_Letter..'(.)')
function getAlphabet ()
    local letters = {}
    for ascii = 97, 122 do table.insert(letters, string.char(ascii)) end
    for key,value in ipairs(uniqueCharacters) do table.insert(letters, value) end
    return letters
end
 
local alpha = getAlphabet()
-- DebugPrint(alpha[25] .. alpha[1] .. alpha[25]..alpha[28]) 


function tick(dt )
	-- if(InputPressed("rmb")) then
	-- 	DebugPrint("rmb pressed")
	-- end
	if(changingKey and (InputPressed("any") or InputPressed("rmb") )) then

		-- DebugPrint("rmb pressed")
		for key,value in ipairs(alpha) do
			if(InputPressed(value)) then
				SetString("savegame.mod.controls."..selectedKey,value)
				selectedKey = ""
				changingKey = false
			end
		end
	end

end


function draw()

	UiPush()
	UiTranslate(UiCenter(), 50)
	UiAlign("center top")

	--Title
	UiImageBox("MOD/gfx/AVF_logo.png",400,400,1,1)
	UiTranslate(0, 300)
	UiFont("bold.ttf", 48)
	UiText("Armed Vehicles Framework (AVF) Options")
	UiPop()
	---AVF_logo


	UiTranslate(UiCenter()/2, 150)
	UiFont("regular.ttf", 26)
	UiButtonImageBox("ui/common/box-outline-6.png", 6, 6)
	UiPush()
		UiTranslate(-110, 0)
		UiAlign("center left")
		for key,val in ipairs(armedVehicleControlsOrder) do
			local inputKey = armedVehicleControls[val] 
			key = val

			if(GetString("savegame.mod.controls."..key,val)~="")then
				inputKey = GetString("savegame.mod.controls."..key,inputKey)
			end
			local displayText = string.format("%-10s %5s",key..": ",inputKey)
			
			if(changingKey and selectedKey == key) then
				displayText = string.format("%-10s %5s",key..": ","____")
				UiTextButton(displayText, 250, 40)
			else
				if UiTextButton(displayText, 250, 40) and not changingKey then
					
					changingKey = true
					selectedKey = key

				end
			end	
			UiTranslate(0, 40)
		end
		UiTranslate(0, 40)
		if UiTextButton("Reset Defaults", 250, 40) then
			for key,val in pairs(armedVehicleControls) do
				SetString("savegame.mod.controls."..key,val)

			end

		end

	UiPop()


	
	UiTranslate(UiCenter(), 250)
	--Draw buttons
	UiTranslate(0, 200)
	UiFont("regular.ttf", 26)
	UiButtonImageBox("ui/common/box-outline-6.png", 6, 6)
	UiPush()
		UiTranslate(-110, -100)
		-- if not GetBool("savegame.mod.mph") then
		-- 	UiPush()
		-- 		UiColor(0.5, 1, 0.5, 0.2)
		-- 		UiImageBox("ui/common/box-solid-6.png", 200, 40, 6, 6)
		-- 	UiPop()
		-- end
		local debugText = "Enable"
		if(GetBool("savegame.mod.debug")) then
			debugText = "Disable"
		end
		if UiTextButton(debugText.." Debug Mode", 250, 40) then
			SetBool("savegame.mod.debug", not GetBool("savegame.mod.debug"))
		end	
		UiTranslate(0, 50)
		local infiniteAmmoText = "Enable"
		if(GetBool("savegame.mod.infiniteAmmo")) then
			infiniteAmmoText = "Disable"
		end
		if UiTextButton(infiniteAmmoText.." Infinite Ammo", 250, 40) then
			SetBool("savegame.mod.infiniteAmmo", not GetBool("savegame.mod.infiniteAmmo"))
		end	
		UiTranslate(0, 50)
		local controlsHudText = "Hide"
		if(GetBool("savegame.mod.hideControls")) then
			controlsHudText = "Show"
		end
		if UiTextButton(controlsHudText.." Controls HUD", 250, 40) then
			SetBool("savegame.mod.hideControls", not GetBool("savegame.mod.hideControls"))
		end


		-- UiTranslate(270, 0)
		-- if GetBool("savegame.mod.mph") then
		-- 	UiPush()
		-- 		UiColor(0.5, 1, 0.5, 0.2)
		-- 		UiImageBox("ui/common/box-solid-6.png", 200, 40, 6, 6)
		-- 	UiPop()
		-- end
		-- if UiTextButton("Imperial MPH", 200, 40) then
		-- 	SetBool("savegame.mod.mph", true)
		-- end
	UiPop()
	
	UiTranslate(0, 100)
	if UiTextButton("Close", 200, 40) then
		Menu()
	end
end

