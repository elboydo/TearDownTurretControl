
#include "mountedGun.lua"

--[[
 Vehicle config
]]

vehicle = {
	mainName 				= "technicalVehicleSPG",
	Vehiclename 			= "technicalBodySPG",
  	CannonName 				= "SPG",
  	CannonJointName 		= "SPGgunMount",
  	Create 					= "elboydo",
  	barrelOffset 			= .6
}
--[[
 rocket Launcher config
]]

weaponFeatures = {
	armed 					= true,
	timeToFire 				= 1,
	magazineCapacity 		= 5,
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
	rocketExtraconsumption 	= 5,
	rocketReloadPenalty 	= 1 
}

function init()
	setValues(vehicle,weaponFeatures)
	gunInit()

	end

function tick(dt)
	gunTick(dt)
end