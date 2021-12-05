armedVehicleControls = {
	fire 				= "lmb",
	sniperMode 			= "rmb",
	elevateGun			= "c",
	depressGun 			= "x",
	changeWeapons		= "r",
	changeTurretGroup	= "t",
	changeAmmunition	= "f",
	deploySmoke			= "g",
	lockAngle			= "j",
	lockRotation		= "k",
	toggle_Searchlight =  "l",
}

armedVehicleControlsOrder = {
	[1] 			="fire",
	[2] 			= "sniperMode",
	[3] 			= "elevateGun",
	[4]				= "depressGun",
	[5] 			= "changeWeapons",
	[6]				= "changeAmmunition",
	[7]				= "deploySmoke",
	[8]				= "lockAngle",
	[9]				= "lockRotation",
	[10]			="toggle_Searchlight",
}



function loadCustomControls()
	for key, value in pairs(armedVehicleControls) do 
		
		if GetString("savegame.mod.controls."..key)~="" then
			armedVehicleControls[key] =  GetString("savegame.mod.controls."..key)
		end
	end

end