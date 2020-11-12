
#include "mountedGun.lua"

--[[
 Vehicle config
]]

vehicle = {
	mainName 				= "technicalVehicle",
	Vehiclename 			= "technicalBody",
  	CannonName 				= "canon",
  	CannonJointName 		= "gunMount",
  	Create 					= "elboydo",
  	barrelOffset 			= .6
}
--[[
 Mounted gun config
]]

weaponFeatures = {
	armed 					= true,
	timeToFire 				= 1,
	magazineCapacity 		= 10,
	reloadTime 				= 1,
	hasRockets 				= false,
	hasRocketCapacity		= false,
	rocketCapacity 			= 50,
	rocketStartingAmmo 		= 25,
	startRockets			= false,  
	hasMG 					= true,
	hasMGCapacity			= false,
	MGCapacity 				= 500,
	MGStartingAmmo 			= 250,
	displayWeaponDetails	= false,
	rocketExtraconsumption 	= 5,
	rocketReloadPenalty 	= 1,
	ammoBoxMGName 			= "mgAmmo",
	ammoBoxRocketName 		= "rocketAmmo"
}

function init()
	setValues(vehicle,weaponFeatures)
	gunInit()

	end

function tick(dt)
	gunTick(dt)
end