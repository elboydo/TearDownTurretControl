
#include "mountedGun.lua"

--[[
 Vehicle config
]]

vehicle = {
	mainName 				= "bmp1_1",
	Vehiclename 			= "bmp1Body",
  	CannonName 				= "bmp1Turret",
  	CannonJointName 		= "bmp1TurretMount",
  	Create 					= "elboydo",
  	barrelOffset 			= 1.2
}
--[[
 rocket Launcher config
]]

weaponFeatures = {
	armed 					= true,
	timeToFire 				= .5,
	magazineCapacity 		= 3,
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