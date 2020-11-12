
#include "mountedGun.lua"

--[[
 Vehicle config
]]

vehicle = {
	mainName 				= "technicalVehicleZU23",
	Vehiclename 			= "technicalBodyZU23",
  	CannonName 				= "ZU23",
  	CannonJointName 		= "ZU23gunMount",
  	Create 					= "elboydo",
  	barrelOffset 			= .6
}
--[[
 rocket Launcher config
]]

weaponFeatures = {
	armed 					= true,
	timeToFire 				= .5,
	magazineCapacity 		= 10,
	reloadTime 				= 1,
	hasRockets 				= true,
	hasRocketCapacity		= false,
	rocketCapacity 			= 50,
	rocketStartingAmmo 		= 25,
	startRockets			= true,  
	hasMG 					= false,
	hasMGCapacity			= false,
	MGCapacity 				= 500,
	MGStartingAmmo 			= 250,
	displayWeaponDetails	= false,
	rocketExtraconsumption 	= 0,
	rocketReloadPenalty 	= .1,
	ammoBoxMGName 			= "",
	ammoBoxRocketName 		= ""
}

function init()
	setValues(vehicle,weaponFeatures)
	gunInit()

	end

function tick(dt)
	gunTick(dt)
end