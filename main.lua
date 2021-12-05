#include "common.lua"
#include "ammo.lua"
#include "weapons.lua"

#include "AIComponent.lua"


#include "explosionController.lua"

#include "controls.lua"
-- #include "../Abu Zayeet Ballistic Range/main/scripts/testing.lua"



--[[
**********************************************************************
*
* FILEHEADER: Elboydo's Armed Vehicles Framework (AVF) 
*
* FILENAME :        main.lua             
*
* DESCRIPTION :
*       File that controls player vehicle turrets within the game teardown (2020)
*
*		File Handles both player physics controlled and in vehicle controlled turrets
*		This is extended to include ammo reloading and weapon group management
*		
*
* SETUP FUNCTIONS :
*		In V3 all initialization is done at level init and based entirely off 
*		Vehicle xml values
*
*
*		In accessor init: 
*
*       setValues(vehicle,weaponFeatures) - Establishes environment variables for vehicle
*       gunInit() 						  - Establishes vehicle gun state
*
*		In accessor Tick(dt):
*
*		gunTick(dt)						  - Manages gun control during gameplay
*
*
*		gunUpdate(d)					  - Manages gun elevation during gameplay
*
*
*
* VEHICLE SETUP 
*
*		add inside tags=""
*
*		vehicle -> cfg=vehicle
*		body -> component=body
*		vox  (for vehicle body) -> component=chassis
*		vox (for turret) -> component=turret turretGroup=mainTurret
*		joint (for turret joint) ->component=turretJoint
*		vox (for gun) -> component=gun weaponType=2A46M group=primary  
*		vox (for gun joint) -> component=gunJoint
*
*
*
* NOTES :
*       Future versions may ammend issue with exact gun location
*		physics based gun control lost after driving player vehicle.
*       
* 		Please ensure to add player click to hud.lua.  (no longer needed)
*
*       Copyright - Of course no copyright but please give credit if this code is 
* 		re-used in part or whole by yourself or others.
*
* AUTHOR :    elboydo        START DATE :    04 Nov 2020
*
*
* ACKNOWLEDGEMENTS:
*
*		Mnay thanks to the many users of the teardown discord for support in coding an establishing this mod,
* 		particularly @rubikow for their invaluable assistance in grasping lua and the functions
*		provided to teardown modders at the inception of this mod, many thanks to Thomasims for guidance on custom projectiles
*		Thanks to spexta for all of the excellent models and assistance involved in developing this mod.  
*
* HUB REPO: https://github.com/elboydo/TearDownTurretControl
*
* CHANGES :
*
*			Release: Public release V_1 - NOV 11 - 11 - 2020
*
*			V2: Added Turret elevation
*					Added crane functionality to control turret 
*					Added high velocity shells
*					+ other quality of life features
*
*			Release: Public release V_1_0_0 - DEC 21 - 12 - 2020
*
*			REMOVED:
*					crane functionality to control turret - replaced with player input
*
*
*			ADDITIONS:
*					Complete rewrite
*					XML driven control
*					Complete XML overrides for weapons
*					Lua controlled weapon / ammo configs
*					Shell penetration
*					Multiple weapon support
*					Multilple gun support
*					Kronenberg 1664 support
*					Dynamic ammo and reloading
*
*					custom projectiles 
*					tracers
*					shrapnal
*					backblast
*					cannon blast
*					snipermode
*					custom sniper zooms					
*
*			Release: Public release V_1_0_8 - DEC 22 - 12 - 2020
*
*
*			Fixed: FOV bug on exiting game when in sniper mode
*			New issue - this will have issues if you change your fov later, can be fixed
*
*
*			Release: Public release V_1_0_9 - JAN 02 - 01 - 2021
*
*
*			Fixed: FOV related Bugs
* 			
*			ADDITIONS:
*				aerial Weapons and rockets. 
*				Customization scripts
*				gravityCoef and dispersionCoef to shells
*
*
*
*			Release: Public release V_1_1_0 - JAN 06 - 01 - 2021
*
*			ADDITIONS:
*				More aerial Weapons and rockets. 
*				guided Missiles
*
*
*			Release: Public release V_1_1_1 - JAN 20 - 01 - 2021
*
*			ADDITIONS:
*				Custom weapon and ammo slot to enable better custom weapons
*				HEAT shells
* 				HESH shells
* 				Spalling / shrapnal mechanics
* 				Improved zoom
* 				ERA armour support
*				
*
*
*			Release: Public release V_1_1_1_75 - FEB 05 - 02 - 2021
*
*
*				Temp fix for loading custom sprites - disabled custom shell sprites
*
*
*
*			Release: Public release V_1_1_2 - FEB 10 - 02 - 2021
*
*			ADDITIONS:
*				Controls hud
*				Demo map
* 				Small fixes
*
*
*
*			Release: Public release V_1_2_1 - MARCH 22 - 03 - 2021
*
*			ADDITIONS:
*				Interacton based control
*
*
*
*
*			Release: Public release V_1_3_0 - June 20 - 06 - 2021
*
*			ADDITIONS:
*				Reworked explosive system for better realism
*				Improved penetration mechanics
*				Added more realistic penetration model
*
**
*
]]

VERSION = "V-1.3.0"


debugMode = false

debugStuff= {

	redCrosses = {}
}

errorMessages = ""
frameErrorMessages = ""

globalConfig = {
	penCheck = 0.1,
	penIteration = 0.1,
	HEATRange = 3,
	gravity = Vec(0,-25,0),
	weaponOrders = {
			[1] = "primary",
			[2] = "secondary",
			[3] = "tertiary",
			[4] = "smoke",
			[5] = "utility1",
			[6] = "utility2",
			[7] = "utility3",
			[8] = "coax",
		},
	MaxSpall = 8,
	spallQuantity = 16,
	spallFactor = {
			kinetic = 0.85,
			AP 		= 0.4,
			APHE    = 0.4,
			HESH 	= 1.8,
			HEI 	= 1,
	},

	materials = {
		rock  = 13,
		dirt  = 0.2,
		plaster = 0.1,
		plastic = 0.05,
		masonry = 0.27,
		glass = 0.05,
		foliage = 0.025,
		wood  = 0.2,
		metal  = 0.42,
		hardmetal = 0.73,
		heavymetal  = 13,
		hardmasonry = 0.6,


	},
}
penVals = "PENETRATION RESULTS\n-------------------------"
--[[
 Vehicle config
]]

vehicle = {
	vehicleName 				= "",
	armed 						= true,
  	Create 						= "elboydo"
  }


 vehicles = {

 }

 ammoContainers = {
 	refillTimer = 0,
 }


vehicleFeatures = {}

defaultVehicleFeatures = {
	weapons = 
		{
			primary 	= {},
			secondary 	= {},
			tertiary 	= {},
			coax    	= {},
			smoke 		= {},
			utility1 	= {},
			utility2 	= {},
			utility3 	= {},
		},
	utility = {
		smoke 		= {},
	},
	equippedGroup = "primary",
	turrets = 
				{
					mainTurret 			= {},
					secondaryTurret 	= {},
					tertiaryTurret 		= {}
				}

}

artillaryHandler = 
{
	shellNum = 1,

	explosionSize = 0.5,

	shells = {

	},
	defaultShell = {active=false, hitPos=nil,timeToTarget =0},
}
shellSpeed = 0.005--5--0.05 --45

projectileHandler = 
	{
		shellNum = 1,
		shells = {

		},
	defaultShell = {active=false, velocity=nil, direction =nil, currentPos=nil, timeLaunched=nil},
	velocity = 200,
	gravity = Vec(0,-25,0),
	shellWidth = 0.3,
	shellHeight = 1.2,
	}


spallHandler = 
	{
		shellNum = 1,
		shells = {

		},
	defaultShell = {active=false, velocity=nil, direction =nil, currentPos=nil, timeLaunched=nil},
	velocity = 200,
	gravity = Vec(0,-25,0),
	shellWidth = 0.3,
	shellHeight = 0.3,
	}


projectorHandler = 
	{
		shellNum = 1,
		shells = {

		},
	defaultShell = {active=false, speed=0, currentPos=nil, hitPos=nil,timeToTarget =0},
	}


maxDist = 500

AVF_Vehicle_Used = false



viewingMap = false

AVF_V3 = {
	interactions = {
		firedLastFrame = false,


	}


}


-- weapon would use xml weaponType= tag then that would relate to the thing

function init()
	-- SetBool("savegame.mod.newVehicle",false)
	-- SetInt("savegame.mod.playerFov",0)
	-- originalFov = SetInt("options.gfx.fov", 90)
	-- if(not GetInt("savegame.mod.playerFov") or GetInt("savegame.mod.playerFov") == 0) then
	-- 	SetInt("savegame.mod.playerFov",GetInt("options.gfx.fov"))
	-- 	-- DebugPrint(GetInt("options.gfx.fov").." | "..GetInt("savegame.mod.playerFov"))
	-- end
	-- DebugPrint(GetInt("options.gfx.fov").." | "..GetInt("savegame.mod.playerFov"))
	-- SetInt("savegame.mod.playerFov",GetInt("options.gfx.fov"))
	originalFov = GetInt("options.gfx.fov")---GetInt("savegame.mod.playerFov")
	-- SetInt("options.gfx.fov",originalFov)
	if(GetBool("savegame.mod.debug")) then	
		debugMode = true
	end


	initCamera()

	reticle1 = LoadSprite("MOD/sprite/reticle1.png")
	reticle2 = LoadSprite("MOD/sprite/reticle2.png")
	reticle3 = LoadSprite("MOD/sprite/reticle3.png")



	globalConfig.gravity = VecScale(globalConfig.gravity,1)

	ammoContainers.crates = FindTriggers("ammoStockpile",true)
	ammoRefillSound = LoadSound(weaponDefaults.refillingAmmo)

	local sceneVehicles = FindVehicles("cfg",true)
	--utils.printStr(#sceneVehicles)

	for i = 1,#sceneVehicles do 
		local value = GetTagValue(sceneVehicles[i], "cfg")
		if(value == "vehicle" and not HasTag(sceneVehicles[i],"AVF_Custom")) then

			local index = #vehicles +1
			vehicles[index] = {
							vehicle ={
									id = sceneVehicles[i],
									groupIndex = index,
									},
							vehicleFeatures = deepcopy(defaultVehicleFeatures),
							}
			vehicle = vehicles[index].vehicle
			vehicleFeatures = vehicles[index].vehicleFeatures


			if(not GetBool("savegame.mod.debug")) then	
				initVehicle(vehicles[index])
			else
				local status,retVal = pcall(initVehicle,vehicles[index])
				if status then 
						-- utils.printStr("no errors")
				else
					errorMessages = errorMessages..retVal.."\n"
				end
			end
		end
	end


	for i =1,250 do
		artillaryHandler.shells[i] = deepcopy(artillaryHandler.defaultShell)

		projectorHandler.shells[i]= deepcopy(projectorHandler.defaultShell)

		projectileHandler.shells[i]= deepcopy(projectileHandler.defaultShell)


		spallHandler.shells[i]= deepcopy(projectileHandler.defaultShell)
	end


	loadCustomControls()

	if(GetBool("savegame.mod.debug")) then	
		utils.printStr("AVF: "..VERSION.." Started!")
	end
		
		-- utils.printStr(testing.test)

	gunSmokedissipation = 3
	gunSmokeSize =1
	gunSmokeGravity = 2

	
	---- setup Complete

	SetBool("level.avf.enabled", true)
	
end



function initVehicle(vehicle_in)

	if unexpected_condition then error() end
	vehicle.body = GetVehicleBody(vehicle.id)
	vehicle.transform =  GetBodyTransform(vehicle.body)
	vehicle.shapes = GetBodyShapes(vehicle.body)
	vehicle.sniperFOV = originalFov
	totalShapes = ""

	vehicle.lights = {}

	for i=1,#vehicle.shapes do
		if(HasTag(vehicle.shapes[i],"commander")) then
			 vehicleFeatures.commanderPos = vehicle.shapes[i]
		end
			
		local value = GetTagValue(vehicle.shapes[i], "component")
		if(value~= "")then

			totalShapes = totalShapes..value.." "

			local test = GetShapeJoints(vehicle.shapes[i])
				for j=1,#test do 
					local val2 = GetTagValue(test[j], "component")
					if(val2~= "")then

						
						totalShapes = totalShapes..val2.." "

						if(val2=="turretJoint")then

							totalShapes = totalShapes..traverseTurret(test[j], vehicle.shapes[i])

						elseif val2=="gunJoint" then
							
							local status,retVal = pcall(addGun,test[j], vehicle.shapes[i])
							if status then 
							-- utils.printStr("no errors")
							else
								errorMessages = errorMessages..retVal.."\n"
							end
							-- totalShapes = totalShapes..addGun(test[j], vehicle.shapes[i])

						end
					end
				end
			
		
			if(HasTag(vehicle.shapes[i],"smokeLauncher")) then

				addSmokeLauncher(vehicle.shapes[i])

			end	


		end	

	-- utils.printStr(totalShapes)
	-- DebugPrint(totalShapes)
	end
	local count = 1
	-- local tstStrn = "test" 
	vehicleFeatures.validGroups = {}
	vehicleFeatures.currentGroup =1
	for key,val in ipairs(globalConfig.weaponOrders) do
		
		if(#vehicleFeatures.weapons[val]>0)then
			vehicleFeatures.validGroups[count] = val
			count = count +1
			-- tstStrn = tstStrn.."\n"..key.." "..count
		end
	end


	vehicleFeatures.equippedGroup = vehicleFeatures.validGroups[vehicleFeatures.currentGroup]
	-- for key,val in ipairs(globalConfig.weaponOrders) do
	-- 	if(vehicleFeatures.validGroups[vehicleFeatures.currentGroup] == val) then
	-- 		DebugPrint(val.." | "..vehicleFeatures.validGroups[vehicleFeatures.currentGroup])

	-- 		vehicleFeatures.equippedGroup = vehicleFeatures.validGroups[vehicleFeatures.currentGroup]
	-- 	end
	-- end
	if not vehicleFeatures.commanderPos then
		if(#vehicleFeatures.turrets.mainTurret>0) then
			vehicleFeatures.commanderPos = vehicleFeatures.turrets.mainTurret[1].id
		else

			vehicleFeatures.commanderPos = vehicle.shapes[1]
		end

	end

	vehicle.ZOOMVAL   = 0.1
	vehicle.ZOOMMAX   = 8
	vehicle.ZOOMMIN   = 0 
	vehicle.ZOOMLEVEL = vehicle.ZOOMMIN   

	initAI()



	-- utils.printStr(tstStrn)
end


function initAI()

	if(HasTag(vehicle.id,"avf_ai")) then
		AVF_ai:initAi()
		DebugPrint("Vehicle: "..vehicle.id.." is ai ready")
	end
end

function tick(dt)
	frameErrorMessages = ""
	


	-- if(AVF_Vehicle_Used and (InputPressed("esc") or InputDown("esc") or InputReleased("esc"))) then
	-- 	SetInt("options.gfx.fov",originalFov)
	-- end


	-- gameplayTicks(dt)
					local status,retVal = pcall(gameplayTicks,dt)
					if status then 
							-- utils.printStr("no errors")
						else
							frameErrorMessages = frameErrorMessages..retVal.."\n"
						end
	playerTicks(dt)


	pollNewVehicle(dt)

	if(GetBool("savegame.mod.debug")) then	
		DebugWatch("Errors: ",errorMessages)
		DebugWatch("Frame errors",frameErrorMessages)
	end

	if(debugMode) then 
		if(#debugStuff.redCrosses>0) then
			for i = 1,#debugStuff.redCrosses do
				DebugCross(debugStuff.redCrosses[i],1,0,0)

			end
		end
	end

	-- DebugWatch("x: ",InputValue("mousedx"))
	-- DebugWatch("y: ",InputValue("mousedy"))
	-- DebugWatch("fox: ",GetInt("options.gfx.fov", fov))

	-- if(AVF_Vehicle_Used and (InputPressed("esc") or InputDown("esc") or InputReleased("esc"))) then
	-- 	SetInt("options.gfx.fov",originalFov)
	-- end

end

function gameplayTicks( dt )
	if unexpected_condition then error() end
	projectileTick(dt)


	spallingTick(dt)

	projectorTick(dt)
	
	artillaryTick(dt)



	interactionTicks(dt)

	--- to be implemented

	AVF_ai:aiTick(dt)

	reloadTicks(dt)



	ammoRefillTick(dt)

	explosionController:tick(dt)
end

function playerTicks( dt )
	
	if(
		(GetBool("game.player.usevehicle") )) 
	then
			
			inVehicle, vehicleid = playerInVehicle()
				if(inVehicle)then 



					if(not AVF_Vehicle_Used) then
						AVF_Vehicle_Used = true
					end
					vehicle = vehicles[vehicleid].vehicle
					vehicleFeatures = vehicles[vehicleid].vehicleFeatures

					if(not viewingMap or not vehicle.sniperMode) then 
						manageCamera()
					end

					if(vehicle.sniperMode) then
						handleSniperMode(dt)
					end
						handleInputs(dt)
						handleGunOperation(dt)

					handleUtilityReloads(dt)
				end

	elseif(viewingMap) then
		viewingMap = false
	end
end



function interactionTicks(dt)
	if(GetPlayerVehicle()==0) then 

		local interactGun = GetPlayerInteractShape()
	--SetTag(gun, "AVF_Parent", vehicle.groupIndex )


		--- check for palyer inpyut and if player nput found then allocate the vehicle based on tag val. 
			--- then do cool stuff
		if(HasTag(interactGun,"AVF_Parent") and  getPlayerInteactInput()) then 

			-- DebugPrint("AVF_Parent val: "..GetTagValue(interactGun,"AVF_Parent").." gun index: "..interactGun)
			interactVehicle = vehicles[tonumber(GetTagValue(interactGun,"AVF_Parent"))]
			vehicle = interactVehicle.vehicle
			vehicleid = vehicle.groupIndex
			vehicleFeatures = interactVehicle.vehicleFeatures
			handleInteractedGunOperation(dt,interactGun)

		end
		local interactGun  =  GetPlayerGrabShape()
		if(HasTag(interactGun,"AVF_Parent") and  getPlayerGrabInput()) then 

			-- DebugPrint("AVF_Parent val: "..GetTagValue(interactGun,"AVF_Parent").." gun index: "..interactGun)
			interactVehicle = vehicles[tonumber(GetTagValue(interactGun,"AVF_Parent"))]
			vehicle = interactVehicle.vehicle
			vehicleid = vehicle.groupIndex
			vehicleFeatures = interactVehicle.vehicleFeatures
			handleGrabGunReset(interactGun)

		end
	end

end

function reloadTicks(dt)
	for key,vehicle in pairs(vehicles) do
		vehicleFeatures = vehicle.vehicleFeatures

		--- reload all weapons 
		for key,gunGroup in pairs(vehicleFeatures.weapons) do

			for key2,gun in ipairs(gunGroup) do
				if(HasTag(gun.id, "interact") and 
					(IsJointBroken(gun.gunJoint) or (gun.turretJoint and IsJointBroken(gun.turretJoint)))) then 
					RemoveTag(gun.id, "interact")
				end


				if(gun.reloading) then
					handleReload(gun,dt)
				end
			end

		end
		---
end

end


function update(dt)

	if(
		(GetBool("game.player.usevehicle") )) 
	then
			
			inVehicle, vehicleid = playerInVehicle()
				if(inVehicle)then 
					-- if(InputPressed("esc") or InputDown("esc") or InputReleased("esc")) then
					-- 	SetInt("options.gfx.fov",originalFov)
					-- end
					if(not AVF_Vehicle_Used ) then
						AVF_Vehicle_Used = true
					end
					vehicle = vehicles[vehicleid].vehicle
					vehicleFeatures = vehicles[vehicleid].vehicleFeatures
					handlegunAngles()
					if(not vehicle.sniperMode) then
						for key,turretGroup in pairs(vehicleFeatures.turrets) do
							for key2,turret in ipairs(turretGroup) do
								if(not IsJointBroken(turret.turretJoint)) then
									local status,retVal = pcall(turretRotatation,turret,turret.turretJoint);
									if status then 
										-- utils.printStr("no errors")
									else
										errorMessages = errorMessages..retVal.."\n"
									end
								-- turretRotatation(turret.id,turret.turretJoint)
								end
							end
						end 	
						handleGunMovement(dt)
					end
				end
	else
		-- if(AVF_Vehicle_Used) then
		-- 	SetInt("options.gfx.fov",originalFov)
		-- 	AVF_Vehicle_Used = false
		-- end 
		for _, vehicle in pairs(vehicles) do 					

			for key,turretGroup in pairs(vehicle.vehicleFeatures.turrets) do

				for key2,turret in ipairs(turretGroup) do
					SetJointMotor(turret.turretJoint, 0)
				end
			end
		end
	end
	if(explosionController.update~=nil) then 
		-- DebugWatch("controlelr func exist",explosionController.update==nil)
		-- DebugWatch("controlller tst",explosionController.test)
		
		-- DebugWatch("controlller",explosionController:testFunc())
		explosionController:update(dt)
	end
	-- if(AVF_Vehicle_Used and(InputPressed("esc") or InputDown("esc") or InputReleased("esc"))) then
	-- 	SetInt("options.gfx.fov",originalFov)
	-- end
end



function handleLightOperation()
	if(InputPressed(armedVehicleControls.toggle_Searchlight)) then
		local light = nil
		for i=1, #vehicle.lights do
			light = vehicle.lights[i]
			if(IsLightActive(light)) then
				SetLightEnabled(light,false)
			else

				SetLightEnabled(light,true)
			end

		end

	end
end

function handleGunMovement(dt)
	local gunGroup = vehicleFeatures.weapons[vehicleFeatures.equippedGroup]
	local gunMovement = 0
	if(InputPressed(armedVehicleControls.elevateGun)or InputDown(armedVehicleControls.elevateGun)) then
		gunMovement = 1
	elseif InputPressed(armedVehicleControls.depressGun) or InputDown(armedVehicleControls.depressGun) then
		gunMovement = -1

	end
		
	local bias = 0.25
	-- local gunGroup = vehicleFeatures.weapons[vehicleFeatures.equippedGroup]
	for key2,gun in ipairs(gunGroup) do
		if(not IsJointBroken(gun.gunJoint) and not (gun.turretJoint and IsJointBroken(gun.turretJoint)))then	
			if(gun.locked) then
				gunMovement = lockedGunAngle(gun)

			end
			if(gun.elevationSpeed) then
				bias = gun.elevationSpeed
			end
			-- utils.printStr(gun.magazines[gun.loadedMagazine].name)
			if(gunMovement~= 0)then
				gun.moved = true
			end
			SetJointMotor(gun.gunJoint, gunMovement*bias)
		end
	end
	 
end


function handleSniperMode(dt ) 
	if unexpected_condition then error() end


	local gunGroup = vehicleFeatures.weapons[vehicleFeatures.equippedGroup]
	local testgunobj = gunGroup[1].id

	local focusGun = gunGroup[1]
	local y = tonumber(focusGun.sight[1].y)
	local x = tonumber(focusGun.sight[1].x)
	local z = tonumber(focusGun.sight[1].z)




	local commanderPos = GetShapeWorldTransform(vehicleFeatures.commanderPos) 
	local focusGunPos = GetShapeWorldTransform(focusGun.id) 

	local cmddist = 200
	if(GetBool("savegame.mod.horizontalGunLaying")) then
		QueryRejectBody(vehicle.body)
		QueryRejectShape(focusGun.id)
		local cmdfwdPos = TransformToParentPoint(focusGunPos, Vec(0,  200 * -1),1)
	    local cmddirection = VecSub(cmdfwdPos, focusGunPos.pos)
	    cmddirection = VecNormalize(cmddirection)
	    QueryRequire("physical")
	    cmdhit, cmddist = QueryRaycast(focusGunPos.pos, cmddirection, 200)
	    DebugWatch("dist",cmddist)
	end
	-- DebugWatch("x: ",x)
	-- DebugWatch("y: ",y)
	-- DebugWatch("z: ",z)
	local deadzone = 0
	local commanderPos = GetShapeWorldTransform(vehicleFeatures.commanderPos) --vehicleFeatures.turrets.mainTurret[1].id)
	-- local commanderPos = GetVehicleTransform(vehicle.id)
	local posLoc  = TransformToParentPoint(commanderPos, Vec(x,  z, y ))
	local fwdLoc  = TransformToParentPoint(commanderPos, Vec(x,  z-2,y ))
	local direction = VecSub(posLoc, commanderPos.pos)

	commanderPos.rot = QuatLookAt(posLoc,fwdLoc)
	-- commanderPos.rot = QuatRotateQuat(commanderPos.rot,QuatEuler(0, 0, 0))
	commanderPos.pos = VecAdd(commanderPos.pos, direction)

	-- DebugWatch("x type",type(x))
	----
	local bias = utils.sign(x)

	local primary = GetJointMovement(gunGroup[1].gunJoint)
	
	commanderPos.rot = QuatRotateQuat(commanderPos.rot,QuatEuler(-primary,0, 0))

	local testCommander =  TransformToParentPoint(commanderPos,Vec(0,000,-200))
	local testGun =  TransformToParentPoint( GetShapeWorldTransform(testgunobj),Vec(0,-180,0))
	local offSetAngle = (math.atan(VecLength(VecSub(testCommander,testGun))/cmddist)*10)*bias

	if(focusGun.aimForwards) then
		offSetAngle = 0
	end

	-- 	DebugWatch("test veclength: ",VecLength(VecSub(testCommander,testGun)))
	-- DebugWatch("test angle: ",offSetAngle)

	commanderPos.rot = QuatRotateQuat(commanderPos.rot,QuatEuler(0,-offSetAngle, 0))
	

	local mousewheel = InputValue("mousewheel")
	if(mousewheel > 0 and vehicle.ZOOMLEVEL <vehicle.ZOOMMAX) then
		vehicle.ZOOMLEVEL  = vehicle.ZOOMLEVEL + 1
	elseif(mousewheel < 0 and vehicle.ZOOMLEVEL >vehicle.ZOOMMIN)then 
		vehicle.ZOOMLEVEL = vehicle.ZOOMLEVEL - 1
	end
	local ZOOMVALUE = 1 - (vehicle.ZOOMVAL * vehicle.ZOOMLEVEL)
	-- local mousewheel = InputValue("mousewheel")
	-- if(mousewheel > 0 and vehicle.sniperFOV >20) then
	-- 	vehicle.sniperFOV  = vehicle.sniperFOV - 10
	-- elseif(mousewheel < 0 and vehicle.sniperFOV <originalFov)then 
	-- 	vehicle.sniperFOV = vehicle.sniperFOV + 10
	-- end
	-- DebugWatch("mouse wheel",mousewheel)

	-- DebugWatch("VecLength: ",VecLength(VecSub(commanderPos.pos,GetShapeWorldTransform(vehicleFeatures.turrets.mainTurret[1].id).pos)))
	local rotateSpeed = (vehicle.sniperFOV*ZOOMVALUE) / vehicle.sniperFOV
	
	local mouseX = -InputValue("mousedx")
	local mouseY = -InputValue("mousedy")


	if(debugMode)then
		DebugWatch("MouseX",mouseX)
		DebugWatch("MouseY",mouseY)
	end

		if(#vehicleFeatures.turrets.mainTurret>0)then
			if(math.abs(mouseX)>deadzone) then
					
					SetJointMotor(vehicleFeatures.turrets.mainTurret[1].turretJoint, (1*utils.sign(mouseX))*rotateSpeed)
			else
				SetJointMotor(vehicleFeatures.turrets.mainTurret[1].turretJoint, 0)
			end 
		end


		for key,gun in pairs(gunGroup) do
			if(gun.locked) then
				handleGunMovement(dt)
			
			elseif(math.abs(mouseY)>deadzone) then
				if( gun.elevationSpeed) then
					local pre = GetJointMovement(gun.gunJoint)
					SetJointMotor(gun.gunJoint, (gun.elevationSpeed*utils.sign(mouseY))*rotateSpeed)
					gun.moved = true
				else
					SetJointMotor(gun.gunJoint, (1*utils.sign(mouseY))*rotateSpeed)
					gun.moved = true
				end
			else
				if(gun.currentGunjointAngle) then
					
					local bias = 0.25
					if(gun.elevationSpeed) then
						bias = gun.elevationSpeed/10
					end
					SetJointMotor(gun.gunJoint, retainGunAngle(gun)*bias)
				else
					SetJointMotor(gun.gunJoint, 0)
				end
			end 
		end
	SetCameraTransform(commanderPos, vehicle.sniperFOV*ZOOMVALUE)
end

function handleGunOperation(dt)

	local playerShooting,released = getPlayerShootInput()
	local firing = false	
	local gunGroup = vehicleFeatures.weapons[vehicleFeatures.equippedGroup]
	if ((
		(GetBool("game.player.usevehicle") and playerInVehicle()
			and  playerShooting
			 )))
	then
		firing = true
	elseif( released)then
		
		
		-- utils.printStr(#gunGroup)
		for key2,gun in ipairs(gunGroup) do
			if(not gun.reloading and gun.tailOffSound and gun.rapidFire)then
				local cannonLoc = GetShapeWorldTransform(gun.id)
				PlaySound(gun.tailOffSound, cannonLoc.pos, 80)
				gun.rapidFire = false
			end
		end
		
	end

	-- for key,gunGroup in pairs(vehicleFeatures.weapons) do
		-- utils.printStr(#vehicleFeatures.weapons[vehicleFeatures.equippedGroup].." | "..vehicleFeatures.equippedGroup)
	

	-- local gunGroup = vehicleFeatures.weapons[vehicleFeatures.equippedGroup]
	
	-- utils.printStr(#gunGroup)
	for key2,gun in ipairs(gunGroup) do
		if( not IsJointBroken(gun.gunJoint) and  not (gun.turretJoint and IsJointBroken(gun.turretJoint)))then	---not IsShapeBroken(gun.id) and
			if(not gun.magazines[gun.loadedMagazine].outOfAmmo and gun.magazines[gun.loadedMagazine].magazinesAmmo[gun.magazines[gun.loadedMagazine].currentMagazine]) then
	

				local barrelCoords = getBarrelCoords(gun)
				local maxDist = 400				
				----- gun laying 
				if(not vehicle.sniperMode) then 
					autoGunAim(gun,barrelCoords)
				

				end
					--- gun reticle drawing
				if((not vehicle.sniperMode or vehicle.ZOOMLEVEL<=vehicle.ZOOMMIN)) then

					QueryRejectBody(vehicle.body)
					QueryRejectShape(gun.id)
					local fwdPos = TransformToParentPoint(barrelCoords, Vec(0,  maxDist * -1),1)
				    local direction = VecSub(fwdPos, barrelCoords.pos)
				    direction = VecNormalize(direction)
				    QueryRequire("physical")
				    local hit, dist = QueryRaycast(barrelCoords.pos, direction, maxDist)
				    local projectileHitPos = VecAdd(barrelCoords.pos,VecScale(direction, dist))
				    if(hit) then 
			    		local t = Quat()
						t.pos = projectileHitPos
						drawReticleSprite(t)


						setReticleScreenPos(projectileHitPos)

					else
						removeReticleScreenPos()
					end
				end

				local currentMagazine = gun.magazines[gun.loadedMagazine].magazinesAmmo[gun.magazines[gun.loadedMagazine].currentMagazine]
				-- utils.printStr(currentMagazine.AmmoCount)
				if(not gun.reloading and currentMagazine.AmmoCount > 0) then  
					-- utils.printStr(currentMagazine.AmmoCount)
				    if(getPlayerMouseDown() and gun.loopSoundFile)then
				    	if not gun.rapidFire then
				    		
				    		gun.rapidFire = true

				    	end
						local cannonLoc = GetShapeWorldTransform(gun.id)

						PlayLoop(gun.loopSoundFile, cannonLoc.pos, 5)
						
					end
					
					if (gun.timeToFire and gun.timeToFire <=0) then
					 	if (firing) then
					 		-- smokeProjection(gun)
					 		
					 		if (gun.cycleTime < dt) then
					 			local firePerFrame =1
					 		
					 			firePerFrame = (math.floor((dt/gun.cycleTime)+0.5))
						 		
						 		-- utils.printStr(firePerFrame)
						 		for i =1, firePerFrame do 
									fireControl(dt,gun)
									currentMagazine.AmmoCount =currentMagazine.AmmoCount -1
									if(currentMagazine.AmmoCount <= 0) then
										break
									end
								end
								
							else
								fireControl(dt,gun)
								currentMagazine.AmmoCount =currentMagazine.AmmoCount -1

							end
							if(currentMagazine.AmmoCount <= 0) then
								local status,retVal = pcall(reloadGun,gun);
								if status then 
									-- utils.printStr("no errors")
								else
									errorMessages = errorMessages..retVal.."\n"
								end
								-- reloadGun(gun)
							end
							
							-- utils.printStr((gun.magazines[gun.loadedMagazine].name))
						end
					elseif (gun.timeToFire) then
						gun.timeToFire = gun.timeToFire - dt
					end

					-- utils.printStr(dt)
				-- elseif(gun.reloading) then
				-- 	-- utils.printStr("reloading")
				-- 	handleReload(gun,dt)
				end
			elseif(playerShooting) then
				PlaySound(gun.dryFire, GetShapeWorldTransform(gun.id).pos, 5)
				-- utils.printStr("gun out of ammo"..gun.magazines[gun.loadedMagazine].name)
			end
		end
	end

	-- end 
end



function handleGrabGunReset(interactGun)
		for key,gunGroup in pairs(vehicleFeatures.weapons) do
		
		-- utils.printStr(#gunGroup)
			for key2,gun in ipairs(gunGroup) do
				if(gun.id == interactGun)then
					SetJointMotor(gun.gunJoint,0,0.1)
				end
			end
		end
end


function handleInteractedGunOperation(dt,interactGun)

	local playerShooting,released = getPlayerInteactInput()
	local firing = false	
	if (
		playerShooting
			 )
	then
		firing = true
	elseif( released)then
		for key,gunGroup in pairs(vehicleFeatures.weapons) do
		
		-- utils.printStr(#gunGroup)
			for key2,gun in ipairs(gunGroup) do
				if(gun.id == interactGun and not gun.reloading and gun.tailOffSound and gun.rapidFire)then
					local cannonLoc = GetShapeWorldTransform(gun.id)
					PlaySound(gun.tailOffSound, cannonLoc.pos, 5)
					gun.rapidFire = false
				end
			end
		end
	end

	for key,gunGroup in pairs(vehicleFeatures.weapons) do
		-- utils.printStr(#vehicleFeatures.weapons[vehicleFeatures.equippedGroup].." | "..vehicleFeatures.equippedGroup)
		
		for key2,gun in ipairs(gunGroup) do
			if(gun.id == interactGun and not IsJointBroken(gun.gunJoint))then	---not IsShapeBroken(gun.id) and
				if(not gun.magazines[gun.loadedMagazine].outOfAmmo and gun.magazines[gun.loadedMagazine].magazinesAmmo[gun.magazines[gun.loadedMagazine].currentMagazine]) then
					local currentMagazine = gun.magazines[gun.loadedMagazine].magazinesAmmo[gun.magazines[gun.loadedMagazine].currentMagazine]
					if(not gun.reloading and currentMagazine.AmmoCount > 0) then  
					    if(getInteractMouseDown() and gun.loopSoundFile)then
					    	if not gun.rapidFire then
					    		
					    		gun.rapidFire = true

					    	end
							local cannonLoc = GetShapeWorldTransform(gun.id)

							PlayLoop(gun.loopSoundFile, cannonLoc.pos, 5)
							
						end
						
						if (gun.timeToFire and gun.timeToFire <=0) then
						 	if (firing) then
						 		
						 		if (gun.cycleTime < dt) then
						 			local firePerFrame =1
						 		
						 			firePerFrame = (math.floor((dt/gun.cycleTime)+0.5))
							 		for i =1, firePerFrame do 
										fireControl(dt,gun)
										currentMagazine.AmmoCount =currentMagazine.AmmoCount -1
										if(currentMagazine.AmmoCount <= 0) then
											break
										end
									end
									
								else
									fireControl(dt,gun)
									currentMagazine.AmmoCount =currentMagazine.AmmoCount -1

								end
								if(currentMagazine.AmmoCount <= 0) then
									local status,retVal = pcall(reloadGun,gun);
									if status then 
									else
										errorMessages = errorMessages..retVal.."\n"
									end
								end
								
							end
						elseif (gun.timeToFire) then
							gun.timeToFire = gun.timeToFire - dt
						end

					end
				elseif(playerShooting) then
					PlaySound(gun.dryFire, GetShapeWorldTransform(gun.id).pos, 5)
				end
			end
		end

	end 
end


function handleReload(gun,dt)
	gun.reloadTime = gun.reloadTime - dt
	if(not gun.reloadPlayOnce)then
		PlayLoop(gun.reloadSound, GetShapeWorldTransform(gun.id).pos, 3)
	end
	if(gun.reloadTime < 0) then
		gun.reloading = false
		gun.timeToFire = 0
		-- gun.magazines[gun.loadedMagazine].currentMagazine.AmmoCount =gun.magazines[gun.loadedMagazine].currentMagazine.magazineCapacity
		-- gun.magazines[gun.loadedMagazine].currentMagazine = gun.magazines[gun.loadedMagazine].nextMagazine
	end
end

function handlegunAngles()
	local gunGroup = vehicleFeatures.weapons[vehicleFeatures.equippedGroup]
	for key2,gun in ipairs(gunGroup) do
		if(not IsJointBroken(gun.gunJoint))then	
			if(gun.moved and not gun.locked) then
				storegunAngle(gun)
				gun.moved = false
			end
		end
	end
end

function storegunAngle(gun)
	gun.currentGunjointAngle = GetJointMovement(gun.gunJoint)
end
--- i have no idea what this function was supposed to originally do, i guess compare last frame to this frame maybe?
function retainGunAngle(gun)
	if(gun.currentGunjointAngle < GetJointMovement(gun.gunJoint)) then
		return 1
	elseif(gun.currentGunjointAngle > GetJointMovement(gun.gunJoint)) then
		return -1
	else
		return 0 
	end
end

function reloadGun(gun)
	if unexpected_condition then error() end
	local loadedMagazine =  gun.magazines[gun.loadedMagazine]
	local currentMagazine =loadedMagazine.magazinesAmmo[gun.magazines[gun.loadedMagazine].currentMagazine]
	if(gun.tailOffSound and gun.rapidFire)then
		local cannonLoc = GetShapeWorldTransform(gun.id)
		PlaySound(gun.tailOffSound, cannonLoc.pos, 5)
		gun.rapidFire = false
	end
	gun.reloading = true
	
	if(currentMagazine.magazineCapacity ==1) then
		gun.reloadTime =  gun.timeToFire
	else 
		gun.reloadTime = gun.reload
	end
	currentMagazine.AmmoCount = currentMagazine.magazineCapacity
	if(currentMagazine.expendedMagazines == gun.magazines[gun.loadedMagazine].magazineCount) then
		gun.magazines[gun.loadedMagazine].outOfAmmo = true
		
		return 0
	end
	if(not GetBool("savegame.mod.infiniteAmmo")) then
	currentMagazine.expendedMagazines = currentMagazine.expendedMagazines+1 
	end
		if(gun.reloadPlayOnce)then
			PlaySound(gun.reloadSound, GetShapeWorldTransform(gun.id).pos, 5)
		end

end


function fireControl(dt,gun,barrelCoords)
	local body = GetShapeBody(gun.id)
	-- utils.printStr("firing "..gun.name.."with "..munitions[gun.default].name.."\n"..body.." "..gun.id.." "..vehicle.body)
	local barrelCoords = rectifyBarrelCoords(gun)
	for i=1, gun.smokeMulti do
		cannonSmoke(dt,gun,barrelCoords)

		
		if(gun.backBlast) then
			local backBlastLoc = barrelCoords
			backBlast(dt,gun,backBlastLoc)
		end
		if(gun.cannonBlast) then
			cannonBlast(gun,barrelCoords)
			
		end
		
	
	end
	
	fire(gun,barrelCoords)
	processRecoil(gun)
	gun.timeToFire = gun.cycleTime
end

function cannonSmoke(dt,gun,barrelCoords)
		
		local cannonLoc = GetShapeWorldTransform(gun.id)
		-- local fwdPos = TransformToParentPoint(cannonLoc, Vec(0, 0, 100))
		local fwdPos = TransformToParentPoint(barrelCoords, Vec(math.random(-3*gun.smokeFactor,3*gun.smokeFactor), 
																math.random(-4*gun.smokeFactor,4*gun.smokeFactor),
																math.random(-3*gun.smokeFactor,2*gun.smokeFactor)))
		local direction = VecSub(fwdPos, cannonLoc.pos)
		-- direction = VecNormalize(direction) 
		smokePos = barrelCoords.pos
		local smokeX = clamp(((direction[1]*360)+math.random(1,10)*0.1),-gunSmokedissipation,gunSmokedissipation)
		local smokeY = clamp((direction[3]*10)+math.random(1,10),-gunSmokedissipation,gunSmokedissipation)
		
		ParticleReset()
		ParticleType("smoke")
		ParticleTile(0)
		local startColour = math.random(20,55)/100

		local endColour = math.random(1,10)/100
		ParticleColor(startColour ,startColour ,startColour ,endColour ,endColour ,endColour )
		ParticleRadius(math.random(0.5,1)*gun.smokeFactor, math.random(1,3)*gun.smokeFactor,"easeout")
		ParticleAlpha(1.0, 0.3,"easeout")
		ParticleGravity(1,-0.8,"easeout")
		ParticleDrag(1)
		ParticleEmissive(1, 0.1,"easeout")
		ParticleRotation(0.5, 0)
		ParticleStretch(0.8)
		ParticleCollide(0, 1, "constant", 0.05)

		SpawnParticle(smokePos,  VecScale(direction,0.25), math.random(3,16))


		-- ParticleReset()
		-- ParticleType("plain")
		-- ParticleTile(5)
		-- ParticleColor(1,1,0, 1,0,0)
		-- ParticleRadius((math.random(0.2,0.4)*gun.smokeFactor),(math.random(0.3,0.5)*gun.smokeFactor)*2)
		-- ParticleAlpha(1.0, 0.8,"easeout")
		-- ParticleGravity(2,1,"easeout")
		-- ParticleDrag(0.2)
		-- ParticleEmissive(1, 0.8,"easeout")
		-- ParticleRotation(0.5, 0)
		-- ParticleStretch(0.8)
		-- ParticleCollide(0, 1, "constant", 0.05)

		-- SpawnParticle(smokePos,  direction, math.random(0.1,1))


		-- SpawnParticle("smoke", smokePos, direction, (math.random(1,gunSmokeSize)*gun.smokeFactor), math.random(1,gunSmokeGravity)*gun.smokeFactor)
		SpawnParticle("fire", smokePos,direction, gun.smokeFactor, .2)

		PointLight(smokePos, 0.8, 0.8, 0.5, math.random(gun.smokeFactor,gun.smokeFactor*3))

		-- SpawnParticle("smoke", smokePos, Vec(-math.random(-1,1)*smokeX, 1.0+math.random(-3,1),math.random(1,1)*smokeY ), (math.random(1,gunSmokeSize)*gun.smokeFactor), math.random(1,gunSmokeGravity)*gun.smokeFactor)
	
end

function backBlast(dt,gun,barrelCoords)
		
		local backBlastLoc = rectifyBackBlastPoint(gun)
		local fwdPos = TransformToParentPoint(backBlastLoc, Vec(math.random(-3,3), math.random(2,6),math.random(-3,3)))
		local direction = VecSub(fwdPos, backBlastLoc.pos)
		local temp = direction[2]
		smokePos = backBlastLoc.pos
		local backBlast = nil
		if(gun.multiBarrel)then
			backBlast = gun.backBlast[gun.multiBarrel]
			
		else 
			backBlast = gun.backBlast[1]
		end
		local smokeX = clamp(((direction[1]*360)+math.random(1,10)*0.1),-gunSmokedissipation,gunSmokedissipation)
		local smokeY = clamp((direction[3]*10)+math.random(1,10),-gunSmokedissipation,gunSmokedissipation)
		
		--[[
			new particle stuff

		]]
		ParticleReset()
		ParticleType("smoke")
		ParticleTile(0)
		local startColour = math.random(20,55)/100

		local endColour = math.random(0,10)/100
		ParticleColor(startColour ,startColour ,startColour ,endColour ,endColour ,endColour )
		ParticleRadius(math.random(0.5,1)*gun.smokeFactor, math.random(2,6)*gun.smokeFactor,"easeout")
		ParticleAlpha(1.0, 0.2)
		ParticleGravity(1,-1,"easeout")
		ParticleDrag(0.8)
		ParticleEmissive(1, 0.1,"easeout")
		ParticleRotation(0.5, 0)
		ParticleStretch(1.0)
		ParticleCollide(1, 1, "constant", 0.05)

		SpawnParticle(smokePos,  direction, math.random(7,18))



		-- ParticleReset()
		-- ParticleType("plain")
		-- ParticleTile(5)
		-- ParticleColor(1,1,0, 1,0,0)
		-- ParticleRadius((math.random(gunSmokeSize,gunSmokeSize*gun.smokeFactor)),(math.random(gunSmokeSize,gunSmokeSize*gun.smokeFactor)*2))
		-- ParticleAlpha(1.0, 0.8,"easeout")
		-- ParticleGravity(2,-0.5,"easeout")
		-- ParticleDrag(0.7)
		-- ParticleEmissive(1, 0.8,"easeout")
		-- ParticleRotation(0.5, 0)
		-- ParticleStretch(0.8)
		-- ParticleCollide(0, 1, "constant", 0.05)

		-- SpawnParticle(smokePos,  direction, math.random(1,3))

		-- SpawnParticle("smoke", smokePos,direction, (math.random(1,gunSmokeSize)*gun.smokeFactor)/2, math.random(1,gunSmokeGravity)*gun.smokeFactor)
		SpawnParticle("fire", smokePos,direction, .6, .3)
		physicalBackblast(gun,backBlastLoc)
	

	-- DebugWatch("Direction: ["..direction[1]..","..direction[2]..","..direction[3].."]".."smokex: "..smokeX.." smoke y :"..smokeY)
end


function physicalBackblast(gun,backBlastLoc)
			local backBlast = nil
			if(gun.multiBarrel)then
				backBlast = gun.backBlast[gun.multiBarrel]
				
			else 
				backBlast = gun.backBlast[1]
			end
			local strength = backBlast.force/10	--Strength of blower
			local maxMass = 2400	--The maximum mass for a body to be affected
			local maxDist = 20	--The maximum distance for bodies to be affected
				--Get all physical and dynamic bodies in front of camera
				-- inVehicle, vehicleid = playerInVehicle()

			local t = backBlastLoc
			local c = TransformToParentPoint(t, Vec(0,  maxDist/2,0))
			local mi = VecAdd(c, Vec(-maxDist/5, -maxDist/5, -maxDist/5))
			local ma = VecAdd(c, Vec(maxDist/5, maxDist/5, maxDist/5))
			QueryRequire("physical dynamic")
			QueryRejectVehicle(vehicles[vehicleid].id)
			local bodies = QueryAabbBodies(mi, ma)


			--Loop through bodies and push them
			for i=1,#bodies do
				local b = bodies[i]


				local rand = (math.random())
				if(rand<.005) then 
					local t = GetBodyTransform(b)
					SpawnFire(t.pos)
				end
			end
			local mi = VecAdd(c, Vec(-maxDist/2, -maxDist/2, -maxDist/2))
			local ma = VecAdd(c, Vec(maxDist/2, maxDist/2, maxDist/2))
			QueryRequire("physical dynamic")
			QueryRejectVehicle(vehicles[vehicleid].id)
			local bodies = QueryAabbBodies(mi, ma)

			--Loop through bodies and push them
			for i=1,#bodies do
				local b = bodies[i]

				--Compute body center point and distance
				local bmi, bma = GetBodyBounds(b)
				local bc = VecLerp(bmi, bma, 0.5)
				local dir = VecSub(bc, t.pos)
				local dist = VecLength(dir)
				dir = VecScale(dir, 1.0/dist)

				--Get body mass
				local mass = GetBodyMass(b)
				
				--Check if body is should be affected
				if dist < maxDist and mass < maxMass then
					--Make sure direction is always pointing slightly upwards
					dir[2] = 0.5
					dir = VecNormalize(dir)
			
					--Compute how much velocity to add
					local massScale = 1 - math.min(mass/maxMass, 1.0)
					local distScale = 1 - math.min(dist/maxDist, 1.0)
					local add = VecScale(dir, strength * massScale * distScale)
					
					--Add velocity to body
					local vel = GetBodyVelocity(b)
					vel = VecAdd(vel, add)
					SetBodyVelocity(b, vel)
				end
			end
end

function cannonBlast(gun,cannonLoc)

			local strength = gun.cannonBlast/10	--Strength of blower
			local maxMass = 2400	--The maximum mass for a body to be affected
			local maxDist = 10	--The maximum distance for bodies to be affected
				--Get all physical and dynamic bodies in front of camera
				-- inVehicle, vehicleid = playerInVehicle()
			local t = cannonLoc
			local c = TransformToParentPoint(t, Vec(0, .5,0))
			local mi = VecAdd(c, Vec(-maxDist, -maxDist/4, -maxDist/2))
			local ma = VecAdd(c, Vec(maxDist, 0, maxDist/2))
			QueryRequire("physical dynamic")
			QueryRejectVehicle(vehicle.id)
			local bodies = QueryAabbBodies(mi, ma)

			--Loop through bodies and push them
			for i=1,#bodies do
				local b = bodies[i]


				--Compute body center point and distance
				local bmi, bma = GetBodyBounds(b)
				local bc = VecLerp(bmi, bma, 0.5)
				local dir = VecSub(bc, t.pos)
				local dist = VecLength(dir)
				dir = VecScale(dir, 1.0/dist)

				--Get body mass
				local mass = GetBodyMass(b)
				
				--Check if body is should be affected
				if dist < maxDist and mass < maxMass then
					--Make sure direction is always pointing slightly upwards
					dir[2] = 0.5
					dir = VecNormalize(dir)
			
					--Compute how much velocity to add
					local massScale = 1 - math.min(mass/maxMass, 1.0)
					local distScale = 1 - math.min(dist/maxDist, 1.0)
					local add = VecScale(dir, strength * massScale * distScale)
					
					--Add velocity to body
					local vel = GetBodyVelocity(b)
					vel = VecAdd(vel, add)
					SetBodyVelocity(b, vel)
				end
			end
end







function rectifyBackBlastPoint(gun)

	local backBlastLoc = GetShapeWorldTransform(gun.id)
	local backBlast = nil
	if(gun.multiBarrel)then
		-- gun.multiBarrel, barrel = next(gun.barrels,gun.multiBarrel)
		backBlast = gun.backBlast[gun.multiBarrel]
		barrel = gun.barrels[gun.multiBarrel]
		
	else 
		backBlast = gun.backBlast[1]
		barrel = gun.barrels[1]
	end
	local backBlastLoc = backBlastLoc
	local y = barrel.y
	local x = barrel.x 
	local z = backBlast.z
	local fwdPos1 = TransformToParentPoint(backBlastLoc, Vec(x, z,y))
	local direction1 = VecSub(fwdPos1, backBlastLoc.pos)
	backBlastLoc.pos = VecAdd(backBlastLoc.pos, direction1)
	return backBlastLoc
	-- body
end

function smokeProjection(projector)
	-- testDistance(projector)
		-- utils.printStr(projector.reload)
		-- local fwdPos = TransformToParentPoint(cannonLoc, Vec(0,  maxDist * -1),1)
  --   local direction = VecSub(fwdPos, cannonLoc.pos)
	 --    direction = VecNormalize(direction)
	 local maxDist = projector.maxDist
	 
	 
	 -- local launchers  	   = 6
	 
	 for i = 1,projector.smokeMulti do 
		 for j = 1, #projector.barrels do

		 	local barrel = projector.barrels[projector.multiBarrel]
		 	local cannonLoc=  rectifyBarrelCoords(projector)
		 	-- utils.printStr("tst")
		 	local projectionAngle =  -(math.sin(math.rad(barrel.y_angle)) * ((maxDist/4)))
		 	local projectionCone  =  (math.sin(math.rad(barrel.x_angle)) * maxDist)
		 	-- utils.printStr(projectionAngle.." | "..projectionCone)
		 	local z = math.abs(projectionCone)
			local fwdPos = TransformToParentPoint(cannonLoc,  Vec(projectionCone, -10+z,projectionAngle))
		    local direction = VecSub(fwdPos, cannonLoc.pos)
		    direction = VecNormalize(direction)
		    QueryRejectBody(vehicle.body)
		    QueryRequire("physical")
		    hit, dist = QueryRaycast(cannonLoc.pos, direction, maxDist)
		    if(hit)then
		    	hitPos = TransformToParentPoint(cannonLoc, Vec(projectionCone, -dist,projectionAngle))
		    else
		    	hitPos = TransformToParentPoint(cannonLoc, Vec(projectionCone, -maxDist+z,projectionAngle))
		    end

		    pushSmoke(projector,hitPos,cannonLoc.pos)
		     -- SpawnParticle("smoke",hitPos, Vec(0, 1, 0), 3, 8)
		    
		end


	 end

	 reloadSmoke(projector)

	
	--  for i =1,2 do
	-- 	 for i = -projectionCone,projectionCone,((projectionCone*2)/launchers) do
	-- 	 	local z = math.abs(i)
	-- 		local fwdPos = TransformToParentPoint(cannonLoc,  Vec(i, -10+z,projectionAngle))
	-- 	    local direction = VecSub(fwdPos, cannonLoc.pos)
	-- 	    direction = VecNormalize(direction)
	-- 	    QueryRejectBody(vehicle.body)
	-- 	    hit, dist = QueryRaycast(cannonLoc.pos, direction, maxDist)
	-- 	    if(hit)then
	-- 	    	hitPos = TransformToParentPoint(cannonLoc, Vec(i, -dist,projectionAngle))
	-- 	    else
	-- 	    	hitPos = TransformToParentPoint(cannonLoc, Vec(i, -maxDist+z,projectionAngle))
	-- 	    end

	-- 	    pushSmoke(projector,hitPos,cannonLoc.pos)
	-- 	     -- SpawnParticle("smoke",hitPos, Vec(0, 1, 0), 3, 8)
		    
	-- 	end
	-- end
	-- body
end

function pushSmoke(projector,hitPos,cannonPos)
	projectorHandler.shells[projectorHandler.shellNum] = deepcopy(projectorHandler.defaultShell)
	-- loadedShell 				= projectorHandler.shells[projectorHandler.shellNum] 
	-- loadedShell.active 			= true
	-- loadedShell.hitPos 			= hitPos
	-- loadedShell.maxDist 		= projector.maxDist
	-- loadedShell.velocity 		= projector.velocity
	-- loadedShell.speed   		= projector.velocity/projector.maxDist
	-- loadedShell.smokeFactor 	= projector.smokeFactor
	-- loadedShell.smokeMulti   	= projector.smokeMulti
	-- loadedShell.pos 			= cannonPos
	-- loadedShell.vel 			= Vec()
	loadedShell 				= projectorHandler.shells[projectorHandler.shellNum] 
	loadedShell.active 			= true
	loadedShell.hitPos 			= hitPos
	loadedShell.maxDist 		= projector.maxDist
	loadedShell.velocity 		= projector.velocity
	loadedShell.speed   		= loadedShell.velocity/loadedShell.maxDist
	loadedShell.smokeFactor 	= projector.smokeFactor
	loadedShell.smokeMulti   	= projector.smokeMulti
	loadedShell.pos 			= cannonPos
	loadedShell.vel 			= Vec()



	-- defaultShell = {active=false, hitPos=nil,timeToTarget =0}
	-- 			maxDist					= 10,
	-- 			magazineCapacity 		= 6,
	-- 			reload 					= 10,
	-- 			smokeFactor 			= .5,
	-- 			smokeMulti				= 1,



	projectorHandler.shellNum = (projectorHandler.shellNum%#projectorHandler.shells) +1
end


function reloadSmoke(projector)
	projector.currentReload = projector.reload
	projector.reloading = true
	-- utils.printStr("reloading smoke")
	-- body
end

function handleUtilityReloads(dt )
	for i=1,#vehicleFeatures.utility.smoke do
			if( vehicleFeatures.utility.smoke[i].reloading) then
				handleSmokeReload(vehicleFeatures.utility.smoke[i],dt)
			end
		end
	-- body
end

function handleSmokeReload(projector,dt)
	projector.currentReload = projector.currentReload -dt
	if(projector.currentReload < 0)then
		projector.reloading = false
	end 

end

function projectorTick(dt)
	local activeShells = 0
		for key,shell in ipairs( projectorHandler.shells  )do
			 if(shell.active==true)then
			 	if(type(shell.hitPos)~= "table")then
			 		shell.active = false
			 	else
				 	activeShells= activeShells+1
				 	if  VecLength(VecSub(shell.pos, shell.hitPos)) <0.3 then
				 		popSmoke(shell)
				 	else
				 		-- shell.timeToTarget = shell.timeToTarget-dt
						local acc = VecSub(shell.hitPos, shell.pos)
						shell.vel = VecAdd(shell.vel, VecScale(acc, shell.speed))
						shell.vel = VecScale(shell.vel, .98)
						shell.pos = VecAdd(shell.pos, VecScale(shell.vel, dt))
						SpawnParticle("smoke",shell.pos, Vec(0, 1, 0), .1, 2)
				 	end
			 	end
			 end
		end
	-- utils.printStr(activeShells)
	-- local acc = VecSub(chopperTargetPos, chopperTransform.pos)
	-- chopperVel = VecAdd(chopperVel, VecScale(acc, dt))
	-- chopperVel = VecScale(chopperVel, 0.98)
	-- chopperTransform.pos = VecAdd(chopperTransform.pos, VecScale(chopperVel, dt))


end

function popSmoke(shell)
	SpawnParticle("smoke",shell.hitPos, Vec(0, 1, 0), shell.smokeFactor, 8)
	shell.active = false
	shell = deepcopy(projectorHandler.defaultShell)
	-- body
end

function smokeGeneratorTick(projector,dt)
	local barrel = projector.barrels[1]
	local projectionX  =  (math.sin(math.rad(barrel.x_angle)) * maxDist)
	local projectionY  =  (math.sin(math.rad(barrel.x_angle)) * maxDist)
	local projectionZ  =  (math.sin(math.rad(barrel.x_angle)) * maxDist)
	if(projector.smokeTime > 0) then
		projector.smokeTime = projector.smokeTime - dt
		SpawnParticle("smoke",shell.pos, Vec(0, shell.y_angle, shell.z_angle), shell.smokeFactor, 2)
	end
	-- body
end

function processRecoil(gun)
	local recoil = 0.01
	if gun.recoil then
		recoil = gun.recoil
	end
	local bodyLoc = GetBodyTransform(vehicle.body)
	local cannonLoc = GetShapeWorldTransform(gun.id)
	
	local fwdPos = TransformToParentPoint(cannonLoc, Vec(0, recoil,0))
    local direction = VecSub(fwdPos, cannonLoc.pos)

	local scaled = VecScale(VecNormalize(direction),recoil)

	-- bodyLoc.pos = VecAdd(bodyLoc.pos,scaled)
	local bodyVelocity = GetBodyVelocity(vehicle.body)
	direction = VecAdd(bodyVelocity,direction)
	SetBodyVelocity(vehicle.body,direction)
	-- SetBodyTransform(vehicle.body,bodyLoc)
end



function testDistance(gun )
	local cannonLoc=  rectifyBarrelCoords(gun)
	QueryRejectBody(vehicle.body)
	local fwdPos = TransformToParentPoint(cannonLoc, Vec(0,  maxDist * -1),0)
    local direction = VecSub(fwdPos, cannonLoc.pos)
    direction = VecNormalize(direction)
    QueryRequire("physical")
    hit, dist = QueryRaycast(cannonLoc.pos, direction, maxDist,.2)
    utils.printStr(dist.." | "..type(norma))
end

function fire(gun,barrelCoords)
    if(gun.mouseDownSound and getPlayerMouseDown())then
    	if(not gun.loopSoundFile)then 
			PlaySound(gun.mouseDownSound, barrelCoords.pos, 50, false)
		end
    elseif(not (gun.tailOffSound ))then
    	PlaySound(gun.sound, barrelCoords.pos, 50, false)
    end


	if(not oldShoot)then
		pushProjectile(barrelCoords,gun)
	else 
		local cannonLoc=  barrelCoords--rectifyBarrelCoords(gun)
			QueryRejectBody(vehicle.body)
			QueryRejectShape(gun.id)
			local fwdPos = TransformToParentPoint(cannonLoc, Vec(0,  maxDist * -1),1)
		    local direction = VecSub(fwdPos, cannonLoc.pos)
		    direction = VecNormalize(direction)
		    QueryRequire("physical")
		    hit, dist = QueryRaycast(cannonLoc.pos, direction, maxDist)
		    -- utils.printStr(dist)

		    if hit then
				hitPos = TransformToParentPoint(cannonLoc, Vec(0, dist * -1,0))
			else
				hitPos = TransformToParentPoint(cannonLoc, Vec(0,  maxDist * -1,0))
			end
		      	p = cannonLoc.pos

				d = VecNormalize(VecSub(hitPos, p))
				spread = 0.03
				d[1] = d[1] + ((math.random()-0.5)*2*spread)*dist/maxDist
				d[2] = d[2] + ((math.random()-0.5)*2*spread)*dist/maxDist
				d[3] = d[3] + ((math.random()-0.5)*2*spread)*dist/maxDist
				d = VecNormalize(d)
				p = VecAdd(p, VecScale(d, 0.5))
				

				-- if(gun.highVelocityShells)then
						-- utils.printStr(gun.loadedMagazine)--type(munitions[gun.magazines[gun.loadedMagazine].name]))
					-- if (gun.magazines[gun.loadedMagazine].CfgAmmo.maxPenDepth and hit) then
							
					-- 	cannonLoc.pos = hitPos
					-- 	pushShell(gun,hitPos,dist,(maxDist-dist),cannonLoc)

					-- else

					-- 	pushShell(gun,hitPos,dist)
					-- end
				-- else
					Shoot(p, d,0)
				-- end		
	end

	

end


---


----- payload handlers


----


function payload_tank_he(shell,hitPos,hitTarget,test)
	Explosion(hitPos,0.3)
	MakeHole(hitPos,shell.shellType.explosionSize*2,shell.shellType.explosionSize*1.5,shell.shellType.explosionSize*0.3)

	explosionController:pushExplosion(hitPos,shell.shellType.explosionSize)

	--- create a series of firethreshold
	local firePos = Vec(0,0,0)
	local unitVec = Vec(0,0,0)
	local maxDist = shell.shellType.explosionSize*2.5
	pushshrapnel(shell.cannonLoc,shell,test,hitTarget)
	for i = 1,math.random(5,30) do
		for xyz = 1,3 do 
			unitVec[xyz] = (math.random()*2)-1 
		end
		QueryRejectShape(hitTarget)
		local hit, dist = QueryRaycast(hitPos,VecNormalize(unitVec),maxDist)
		if hit then
			firePos = VecAdd(hitPos, VecScale(unitVec, dist))
			SpawnFire(firePos)
			-- DebugPrint(dist)

		end
	end

end
---- 

---- PROJECTILE HANDLING

---

function pushProjectile(cannonLoc,gun)
	local fwdPos = TransformToParentPoint(cannonLoc, Vec(0,-1,0))
	local direction = VecSub(fwdPos, cannonLoc.pos)
	-- direction = VecNormalize(direction)
	local point1 = cannonLoc.pos
	
	---
				-- local predictedBulletVelocity = VecScale(direction,velocity)

	projectileHandler.shells[projectileHandler.shellNum] = deepcopy(projectileHandler.defaultShell)

	loadedShell 				= projectileHandler.shells[projectileHandler.shellNum] 
	loadedShell.active 			= true
	loadedShell.shellType = gun.magazines[gun.loadedMagazine].CfgAmmo
	loadedShell.cannonLoc 			= cannonLoc
	loadedShell.point1			= point1
	loadedShell.lastPos 		= point1
	loadedShell.predictedBulletVelocity = VecScale(direction,loadedShell.shellType.velocity)
	loadedShell.originVehicle = vehicle.id
	loadedShell.originPos 	  = GetShapeWorldTransform(gun.id)
	loadedShell.originGun	  = gun.id
	loadedShell.timeToLive	  = loadedShell.shellType.timeToLive
	if(gun.dispersion) then 
		loadedShell.dispersion 	  = gun.dispersion
	else
		loadedShell.dispersion 	  = 1
	end
	local loadedMagazine =  gun.magazines[gun.loadedMagazine]
	local currentMagazine =	loadedMagazine.magazinesAmmo[gun.magazines[gun.loadedMagazine].currentMagazine]
	if (loadedShell.shellType.tracer and 
		 gun.magazines[gun.loadedMagazine].magazinesAmmo[gun.magazines[gun.loadedMagazine].currentMagazine].AmmoCount % loadedShell.shellType.tracer ==0)
	then
		loadedShell.tracer = true
	end
	


	loadedShell.penDepth = loadedShell.shellType.maxPenDepth
	if(globalConfig.penCheck>=loadedShell.shellType.maxPenDepth)then
		loadedShell.maxChecks  =1
	else
		loadedShell.maxChecks = loadedShell.shellType.maxPenDepth/globalConfig.penCheck
	end
	projectileHandler.shellNum = (projectileHandler.shellNum%#projectileHandler.shells) +1

end

function popProjectile(shell,hitTarget)


		local penetration,passThrough,test,penDepth,dist,spallValue =  getProjectilePenetration(shell,hitTarget)
		-- shell.penDepth = shell.penDepth - penDepth

		local holeModifier = math.random(-15,15)/100
			-- DebugPrint("1".." "..shell.penDepth)

		impactEffect(shell,test.pos)


		if(HasTag(hitTarget,"component") and GetTagValue(hitTarget,"component") == "ERA") then
			if(shell.shellType.payload and (shell.shellType.payload == "HEAT" or 
												shell.shellType.payload == "HESH"))  then
				local explosionPos = TransformToParentPoint(Transform(shell.point1,test.rot), Vec(0,-.4,0))
				Explosion(explosionPos,0.5)
				shell.active = false
				for key,val in ipairs( shell ) do 
					val = nil

				end
				shell = deepcopy(projectileHandler.defaultShell)
				return false
			elseif(shell.shellType.payload and (shell.shellType.payload == "AP" or
												shell.shellType.payload == "APHE")) then
				shell.shellType.penDepth = shell.shellType.penDepth /2
			end
		end


		SpawnParticle("smoke", shell.point1, Vec(0,1,0), (math.log(shell.shellType.caliber)/2)*(1+holeModifier), math.random(1,3))
		SpawnParticle("fire", shell.point1, Vec(0,1,0), (math.log(shell.shellType.caliber)/4)*(1+holeModifier) , .25)

		if(shell.shellType.payload and shell.shellType.payload == "HEAT")  then


				MakeHole(shell.point1,shell.shellType.bulletdamage[1]*(1+holeModifier),shell.shellType.bulletdamage[2]*(1+holeModifier), shell.shellType.bulletdamage[3]*(1+holeModifier))
				MakeHole(test.pos,shell.shellType.bulletdamage[1]*(1+holeModifier),shell.shellType.bulletdamage[2]*(1+holeModifier), shell.shellType.bulletdamage[3]*(1+holeModifier))
				
				if(dist > globalConfig.HEATRange or dist == 0) then
					dist = ((shell.shellType.caliber/100)*2)*1.5
				elseif dist <1 then
					dist=(shell.shellType.caliber/100)*2
				end

				local explosionPos = test.pos
				-- DebugPrint(dist)
				-- DebugPrint((shell.shellType.caliber/100)*2)
				for i=1,dist*1.5,0.75 do
					-- DebugPrint("test")
					explosionPos = TransformToParentPoint(test, Vec(0,i*1,0))
		    		-- explosionPos = VecAdd(explosionPos, test.pos)
					Explosion(explosionPos,0.5)
				end
			
			shell.active = false
			for key,val in ipairs( shell ) do 
				val = nil

			end
			shell = deepcopy(projectileHandler.defaultShell)

		elseif(shell.shellType.payload and shell.shellType.payload == "HESH") then
					local explosionPos = TransformToParentPoint(Transform(shell.point1,test.rot), Vec(0,-.45,0))
					Explosion(explosionPos,0.5)
					explosionPos = TransformToParentPoint(test, Vec(0,.35,0))
					MakeHole(explosionPos,shell.shellType.bulletdamage[1]*((1.4+holeModifier)*.5),
								shell.shellType.bulletdamage[2]*((1.2+holeModifier)*.5), 
								shell.shellType.bulletdamage[3]*((1.2+holeModifier)*0.5))

					projectileShrapnel(shell,test,spallValue)
			
			shell.active = false
			for key,val in ipairs( shell ) do 
				val = nil

			end
			shell = deepcopy(projectileHandler.defaultShell)

		elseif(shell.penDepth>0) then		
			-- DebugPrint("2".." "..shell.penDepth)
					-- Explosion(shell.point1,0.5)
					-- MakeHole(shell.point1,1,.7,.5)
					-- gun.magazines[i].CfgAmmo
  				
					-- shellPenetration(shell,test,dist)
					shell.point1 = test.pos
					if shell.shellType.hit and shell.shellType.hit <3 then
						if(shell.shellType.hit ==1)then
							MakeHole(shell.point1,shell.shellType.bulletdamage[1]*(1.4+holeModifier))
						else
							MakeHole(shell.point1,shell.shellType.bulletdamage[1]*(1.4+holeModifier),shell.shellType.bulletdamage[2]*(1.2+holeModifier))
						end

					else
						MakeHole(shell.point1,shell.shellType.bulletdamage[1]*(1.4+holeModifier),shell.shellType.bulletdamage[2]*(1.2+holeModifier), shell.shellType.bulletdamage[3]*(1.2+holeModifier))
					end
					projectileShrapnel(shell,test,spallValue)
					-- SpawnParticle("darksmoke",test.pos, Vec(0, -.1, 0), shell.shellType.bulletdamage[2], 2)
					-- SpawnParticle("darksmoke",test.pos, Vec(0, -.1, 0), shell.shellType.bulletdamage[2], 2)
		else
			-- DebugPrint("3 ".." "..shell.penDepth)
			if(shell.shellType.payload) then
				if(shell.shellType.payload == "high-explosive") then
					Explosion(test.pos,shell.shellType.explosionSize)
				elseif(shell.shellType.payload == "explosive" or shell.shellType.payload == "HE" or shell.shellType.payload == "APHE") then 
					payload_tank_he(shell,test.pos,hitTarget,test)
				elseif(shell.shellType.payload == "incendiary") then
					if shell.shellType.hit and shell.shellType.hit <3 then
						if(shell.shellType.hit ==1)then
							MakeHole(shell.point1,shell.shellType.bulletdamage[1]*(1+holeModifier))
						else

							MakeHole(shell.point1,shell.shellType.bulletdamage[1]*(1+holeModifier),shell.shellType.bulletdamage[2]*(1+holeModifier))
						end

					else
						MakeHole(shell.point1,shell.shellType.bulletdamage[1]*(1+holeModifier),shell.shellType.bulletdamage[2]*(1+holeModifier), shell.shellType.bulletdamage[3]*(1+holeModifier))
					end


					local fireChance = math.random(0,10)/10
					if(fireChance>0.25)then
						SpawnFire(test.pos)
					end
					-- DebugWatch("fire change: ",fireChance)
				elseif(shell.shellType.payload == "HE-I") then

						MakeHole(shell.point1,shell.shellType.bulletdamage[1]*(1+holeModifier),shell.shellType.bulletdamage[2]*(1+holeModifier), shell.shellType.bulletdamage[3]*(1+holeModifier))
					
					SpawnFire(test.pos)
				elseif(shell.shellType.payload == "smoke") then
					-- MakeHole(shell.point1,1,.7,.5)
					local ShellSmoke = math.log(shell.shellType.caliber*2) 
					if( shell.smokeFactor) then
						ShellSmoke = shell.smokeFactor
					end
					for i =1,5 do 
					SpawnParticle("smoke",test.pos, Vec(math.random(-1,1), math.random(-2,1), math.random(-1,1)), ShellSmoke, 10)
					end
				elseif(shell.shellType.payload == "kinetic" or shell.shellType.payload == "AP") then
					if shell.shellType.hit and shell.shellType.hit <3 then
						if(shell.shellType.hit ==1)then
							MakeHole(shell.point1,shell.shellType.bulletdamage[1]*(1+holeModifier))
						else

							MakeHole(shell.point1,shell.shellType.bulletdamage[1]*(1+holeModifier),shell.shellType.bulletdamage[2]*(1+holeModifier))
						end

					else
						MakeHole(shell.point1,shell.shellType.bulletdamage[1]*(1+holeModifier),shell.shellType.bulletdamage[2]*(1+holeModifier), shell.shellType.bulletdamage[3]*(1+holeModifier))
					end
				end
				
			end
			shell.active = false
			for key,val in ipairs( shell ) do 
				val = nil

			end
			shell = deepcopy(projectileHandler.defaultShell)
			-- utils.printStr("penetration  explosion")
		-- shellPenetration(shell)
		-- shell = deepcopy(artillaryHandler.defaultShell)
		end


end


function impactEffect(projectile,hitPos)
	local impactSize = projectile.shellType.bulletdamage[1]

	--fire 
	local q = 1.0 
	for i=1, 16 do
		local v = rndVec(impactSize*1)
		local p = hitPos
		local life = rnd(0.2, 0.7)
		life = 0.5 + life*life*life * 1.5
		ParticleReset()
		ParticleColor(1, 0.6, 0.4, 1, 0.3, 0.2)
		ParticleAlpha(1, 0)
		ParticleRadius((impactSize*0.5)*q, 0.5*(impactSize*0.5)*q)
		ParticleGravity(1, rnd(1, 10))
		ParticleDrag(0.6)
		ParticleEmissive(rnd(2, 5), 0, "easeout")
		ParticleTile(5)
		-- DebugWatch("p",p)
		-- DebugWatch("v",v)
		-- DebugWatch("life",life)
		SpawnParticle(p, v, life)
	end
		--- sparks
	local vel = 3
	for i=1, projectile.shellType.bulletdamage[1]*20 do
		local v = VecAdd(Vec(0, vel, 0 ), rndVec(rnd(vel*0.5, vel*1.5)))
		local life = rnd(0, 1)
		life = life*life * 5
		ParticleReset()
		ParticleEmissive(5, 0, "easeout")
		ParticleGravity(-10)
		ParticleRadius(0.03, 0.0, "easein")
		ParticleColor(1, 0.4, 0.3)
		ParticleTile(4)
		SpawnParticle(hitPos, v, life)
	end
end


function projectileOperations(projectile,dt )
	    projectile.lastPos = projectile.point1
		projectile.cannonLoc.pos = projectile.point1
		local shellHeight = projectile.shellType.shellHeight
		local shellWidth = projectile.shellType.shellWidth
		local r = projectile.shellType.r
		local g = projectile.shellType.g
		local b = projectile.shellType.b
		if(projectile.tracer  ) then

			 shellHeight = shellHeight  * projectile.shellType.tracerL
			 shellWidth = shellWidth  * projectile.shellType.tracerW
			 r = projectile.shellType.tracerR
			 g = projectile.shellType.tracerG
			 b = projectile.shellType.tracerB
		end

		--- sprite drawing
		DrawSprite(projectile.shellType.sprite, projectile.cannonLoc,projectile.shellType.shellWidth,shellHeight , r, g, b, 1, 0, false)
		local altloc = projectile.cannonLoc
		altloc.rot = QuatRotateQuat(altloc.rot,QuatEuler(0, 90,0))
		DrawSprite(projectile.shellType.sprite, altloc, projectile.shellType.shellWidth, shellHeight, r, g, b, 1, 0, false)
		altloc.rot = QuatRotateQuat(projectile.cannonLoc.rot,QuatEuler(90, 0,0))
		DrawSprite(projectile.shellType.spriteRear, altloc, projectile.shellType.shellWidth, projectile.shellType.shellWidth, r, g, b, 1, 0, false)
		

		---
		--- adding sound
		if((projectile.shellType.flightLoopSound)) then
			PlayLoop(projectile.shellType.flightLoopSound, projectile.cannonLoc.pos, 20)
					
		end

		---
		---

			--- PROJECTILE MOTION

		---

		if(projectile.shellType.launcher and projectile.shellType.launcher == "guided") then
			local gunPos = GetShapeWorldTransform(projectile.originGun)
			-- if(vehicleFeatures.commanderPos) then
			-- 	gunPos = GetShapeWorldTransform(vehicleFeatures.commanderPos)
			-- end
			local projectlePos =  TransformCopy(projectile.cannonLoc)
			local length =  VecLength(VecSub(gunPos.pos,projectlePos.pos))
			local atgmfwdPos = VecSub(TransformToParentPoint(gunPos, Vec(0,-length,0)),projectlePos.pos)

			-- if(debugMode)then
			-- 	DebugWatch("atgmFwd: ",VecStr(atgmfwdPos))
			-- 	DebugWatch("gunPos: ",VecStr(gunPos.pos))
			-- 	DebugWatch("atgmPos: ",VecStr(projectlePos.pos))
			-- end
			-- -- local atgmdirection = VecSub(atgmfwdPos, gunPos.pos)
			-- gunPos =  TransformCopy(projectile.cannonLoc)
			--  gunPos.rot  =  QuatRotateQuat(gunPos.rot,QuatEuler(00, -90, -90))
			-- -- gunPos.pos = projectile.cannonLoc.pos
			
			-- local targetAngle =  QuatLookAt(atgmfwdPos,gunPos)
			-- -- targetAngle = QuatSlerp(projectile.cannonLoc.rot, targetAngle, 0.5)
			-- gunPos.rot = targetAngle
			
			-- atgmfwdPos = TransformToParentPoint(gunPos, Vec(0,0,100))

			-- DebugWatch("atgmfwdPos 2: ",VecStr(atgmfwdPos))
			-- atgmdirection = VecSub(atgmfwdPos,gunPos.pos )
			for key,value in pairs(atgmfwdPos) do 
				value = math.log(value)
			end
			-- atgmfwdPos = VecNormalize(atgmfwdPos)
			-- for key,value in pairs(atgmfwdPos) do 
			-- 	value = math.log(math.log(value))/2
			-- end

			-- if(debugMode)then
			-- 	DebugWatch("ATGMDir: ",VecStr(atgmfwdPos))
			-- end
			projectile.predictedBulletVelocity = VecAdd(projectile.predictedBulletVelocity,VecScale(atgmfwdPos,0.05))

		else 

			---  ADDING DISPERSION
			local dispersion = Vec(math.random(-1,1)*projectile.dispersion,math.random(-1,1)*projectile.dispersion,math.random(-1,1)*projectile.dispersion)
			if(projectile.shellType.dispersionCoef) then
				dispersion=VecScale(dispersion,dispersionCoef)
			end
			projectile.predictedBulletVelocity = VecAdd(projectile.predictedBulletVelocity,(VecScale(dispersion,dt)))

			--- APPLYING GRAVITY
			if(projectile.shellType.gravityCoef) then
				local shellGravity = VecScale(globalConfig.gravity,projectile.shellType.gravityCoef)
				projectile.predictedBulletVelocity = VecAdd(projectile.predictedBulletVelocity,(VecScale(shellGravity,dt)))
			else
				projectile.predictedBulletVelocity = VecAdd(projectile.predictedBulletVelocity,(VecScale(globalConfig.gravity,dt)))
			end
		end
		---

		--- EXAUST

		---
		local exaustPos = VecScale(projectile.predictedBulletVelocity,-1)
		-- utils.printStr(VecLength(VecSub(projectile.point1,projectile.originPos.pos)).." | "..VecStr(projectile.point1).." | "..VecStr(projectile.originPos.pos))
		if(VecLength(VecSub(projectile.point1,projectile.originPos.pos))>2)then
			if(projectile.shellType.launcher and (projectile.shellType.launcher == "rocket" or projectile.shellType.launcher == "guided")) then 
				if(VecLength(VecSub(projectile.point1,projectile.originPos.pos))<15)then
					 exaustPos = VecScale(projectile.predictedBulletVelocity,.4)
				elseif(VecLength(VecSub(projectile.point1,projectile.originPos.pos))<30)then

					 exaustPos = VecScale(projectile.predictedBulletVelocity,.7)
				end
				-- local exaustCoef = -math.log(projectile.shellType.caliber)/4
				 exaustPos = VecScale(projectile.predictedBulletVelocity,exaustCoef)
				 local calibreCoef = (math.log(projectile.shellType.caliber)/4) 

				if(projectile.shellType.launcher == "rocket") then
				SpawnParticle("fire",projectile.point1, exaustPos,  1.1*calibreCoef, .15)
				SpawnParticle("smoke",projectile.point1, exaustPos, 1.2*calibreCoef, .3)
				PointLight(projectile.point1, 0.8, 0.8, 0.5, math.random(1*calibreCoef,15*calibreCoef))
				else
					SpawnParticle("darksmoke",projectile.point1, exaustPos, 0.5*calibreCoef, .15)
				end
			else
				-- SpawnParticle("darksmoke",projectile.point1, exaustPos, .3, .15)
			end
		end
	
		local point2 = VecAdd(projectile.point1,VecScale(projectile.predictedBulletVelocity,dt))
		QueryRejectBody(projectile.originVehicle)
		QueryRejectShape(projectile.originGun)
		QueryRequire("physical")
		local hit, dist1,norm1,shape1 = QueryRaycast(projectile.point1, VecNormalize(VecSub(point2,projectile.point1)),VecLength(VecSub(point2,projectile.point1)))
		
		projectile.cannonLoc.rot = QuatRotateQuat(QuatLookAt(point2,projectile.point1),QuatEuler(00, 90, 90))
		
			if(hit)then 
				hitPos = VecAdd(projectile.point1, VecScale(VecNormalize(VecSub(point2,projectile.point1)),dist1))
				projectile.point1 = hitPos
				 popProjectile(projectile,shape1)
				-- -- Explosion(norm1.pos,0.5)
				-- DebugPrint(VecStr(norm1))
			else
				projectile.point1 = point2
			end
		
end

function projectileTick(dt)
		if unexpected_condition then error() end
			local activeShells = 0
			for key,shell in ipairs( projectileHandler.shells  )do
			 	if(shell.active)then
			 		if(shell.timeToLive > 0) then 
			 			projectileOperations(shell,dt)
			 			shell.timeToLive = shell.timeToLive - dt
			 		else
			 			shell.active = false
			 		end
			 	end
		end
end


 -- check left right, if number then explode, if 0 then fly on.
function getProjectilePenetration(shell,hitTarget)
	local cannonLoc = shell.cannonLoc
	cannonLoc.pos = shell.point1
	local penetration = false
	local passThrough = true  
	local test= cannonLoc	
	local outstring =""
	local penDepth =0
	local dist1 = 0
	local hit1=false
	local penDepth = 0
	local holeModifier = math.random(-15,15)/100

	local spallValue = globalConfig.MaxSpall
	local spallCoef = 0

	local mat,r,g,b = GetShapeMaterialAtPosition(hitTarget,test.pos)
	local penValue = globalConfig.materials[mat]
	if(not penValue ) then
		penValue = 0.1
	
		-- DebugWatch("unknown penetration value",mat)
	end
	spallCoef = spallCoef + penValue
	shell.penDepth = shell.penDepth - (penValue * shell.shellType.penModifier)
	if(shell.penDepth < 0) then
		spallValue = spallValue * spallCoef
		return false,false,test,0,0,spallValue
	end

	local damagePoints = {}

	for i =1,30 do 



		if(debugMode) then 
			debugStuff.redCrosses[#debugStuff.redCrosses+1] = test.pos 

			debugStuff.redCrosses[#debugStuff.redCrosses+1] = fwdPos 
		end

		local fwdPos = TransformToParentPoint(test, Vec(0, globalConfig.penIteration * 1,0))
	    local direction = VecSub(fwdPos, test.pos)

	    direction = VecNormalize(direction)
	    QueryRequire("physical")
	    hit1, dist1,norm1,hitTarget  = QueryRaycast(test.pos, direction, globalConfig.penCheck*2)
		mat,r,g,b = GetShapeMaterialAtPosition(hitTarget,test.pos)
		penValue = globalConfig.materials[mat]
		if(not penValue ) then
			penValue = 0.1
		
			-- DebugWatch("unknown penetration value",mat)
		end
		shell.penDepth = shell.penDepth - (penValue * shell.shellType.penModifier)
		spallCoef = spallCoef + penValue
		damagePoints[i] = test.pos
		-- holeModifier = math.random(-15,15)/100
		-- MakeHole(test.pos,shell.shellType.bulletdamage[1]*(1.4+holeModifier),shell.shellType.bulletdamage[2]*(1.2+holeModifier), shell.shellType.bulletdamage[3]*(1.2+holeModifier))

		if(not hit1 or shell.penDepth<0)then


			penDepth = globalConfig.penCheck*i
			penetration=true
			break
		end
		test = rectifyPenetrationVal(test)
	end
	if(dist1 ==0) then

		passThrough = not hit1
		
	end
	for i=1,#damagePoints do 
		holeModifier = math.random(-15,15)/100
		MakeHole(damagePoints[i],shell.shellType.bulletdamage[1]*(1.4+holeModifier),shell.shellType.bulletdamage[2]*(1.2+holeModifier), shell.shellType.bulletdamage[3]*(1.2+holeModifier))

	end
	spallValue = spallValue * spallCoef
	return penetration,passThrough,test,penDepth,dist1,spallValue
end

function projectileShrapnel(projectile,test,spallValue)

			local strength = math.log(projectile.shellType.velocity)*math.log(projectile.shellType.caliber)	--Strength of blower
			local maxMass = 2400	--The maximum mass for a body to be affected
			local maxDist = 1	--The maximum distance for bodies to be affected
				--Get all physical and dynamic bodies in front of camera
			
			local t = test
			
			local t1 = TransformToParentPoint(t, Vec(0,  maxDist/2,0))
			local c = TransformToParentPoint(t, Vec(0, -maxDist/2, 0))
			local mi = VecAdd(c, Vec(-maxDist/2, -maxDist/2, -maxDist/2))
			local ma = VecAdd(c, Vec(maxDist/2, maxDist/2, maxDist/2))
			QueryRequire("physical dynamic")
			
			local bodies = QueryAabbBodies(mi, ma)

			--Loop through bodies and push them
			for i=1,#bodies do
				local b = bodies[i]


				--Compute body center point and distance
				local bmi, bma = GetBodyBounds(b)
				local bc = VecLerp(bmi, bma, 0.5)
				local dir = VecSub(t1, bc )
				local dist = VecLength(dir)
				dir = VecScale(dir, 1.0/dist)

				--Get body mass
				local mass = GetBodyMass(b)
				
				--Check if body is should be affected
				if dist < maxDist and mass < maxMass then
					--Make sure direction is always pointing slightly upwards
					dir[2] = 0.1
					dir = VecNormalize(dir)
			
					--Compute how much velocity to add
					local massScale = 1 - math.min(mass/maxMass, 1.0)
					local distScale = 1 - math.min(dist/maxDist, 1.0)
					local add = VecScale(dir, strength * massScale * distScale)
					
					--Add velocity to body
					local vel = GetBodyVelocity(b)
					vel = VecAdd(vel, add)
					SetBodyVelocity(b, vel)
				end
			end

			pushSpalling(projectile.cannonLoc,projectile,test,spallValue)
end



----

------ SPALLING and SHRAPNAL HANDLING

function pushSpalling(spallingLoc,spallShell,test,spallValue)

	---			kinetic = 0.8,
			-- AP 		= 0.3,
			-- APHE    = 0.3,
			-- HESH 	= 2,
			-- HEI 	= 1,

	local spallFactor = 0.25
	if(spallShell.shellType.payload) then
		local spallPayload = spallShell.shellType.payload
		if(spallShell.shellType.payload =="AP") then
			spallFactor = globalConfig.spallFactor.AP
		elseif(spallShell.shellType.payload =="APHE") then
			spallFactor = globalConfig.spallFactor.APHE
		elseif(spallShell.shellType.payload =="HESH") then
			spallFactor = globalConfig.spallFactor.HESH
		elseif(spallShell.shellType.payload =="HEI" or spallShell.shellType.payload =="HE-I") then
			spallFactor = globalConfig.spallFactor.HEI
		elseif(spallShell.shellType.payload =="kinetic") then
			spallFactor = globalConfig.spallFactor.kinetic	
		end


	end
	for i=1,math.random(1,spallValue*spallFactor) do 

		local spallingSizeCoef = math.random(1,4)/10

		if(spallShell.shellType.payload == "HESH")then
			spallingSizeCoef = spallingSizeCoef * globalConfig.spallFactor.HESH
		end

		-- test.rot = QuatLookAt(spallShell.lastPos,test)
		local spallPos = TransformCopy(test)
		-- spallPos.pos = TransformToParentPoint(spallPos, 0,-16,0)
		local fwdPos = TransformToParentPoint(spallPos, Vec(math.random(-10,10),-10,math.random(-10,10)))
		local direction = VecSub( fwdPos,spallPos.pos)
		local point1 = spallPos.pos
					
		spallHandler.shells[spallHandler.shellNum] = deepcopy(spallHandler.defaultShell)

		local currentSpall 				= spallHandler.shells[spallHandler.shellNum] 
		currentSpall.active 			= true 
		currentSpall.shellType = deepcopy(spallShell.shellType) 
		currentSpall.cannonLoc 			= spallPos
		currentSpall.point1			= point1 
		currentSpall.predictedBulletVelocity = VecScale(spallShell.predictedBulletVelocity,0.3)
		-- currentSpall.predictedBulletVelocity = VecScale(
		-- 												VecAdd(
		-- 													VecScale(spallShell.predictedBulletVelocity,0.8),fwdPos),0.5)
		--VecScale(direction,currentSpall.shellType.velocity*.2)
		currentSpall.originPos 	  = spallPos 
		currentSpall.timeToLive	  = (currentSpall.shellType.timeToLive *(spallingSizeCoef+0.2))*(math.random(50,100)/100)
		if(spallShell.dispersion) then 
			currentSpall.dispersion 	  = 200 
			else
			currentSpall.dispersion 	  = 100 
		end
		-- DebugPrint("velocity: "..VecStr(currentSpall.predictedBulletVelocity).."  | pos = "..VecStr(TransformToParentPoint(spallPos, 0,-16,0)).." | "..VecStr(test.pos))

		currentSpall.shellType.bulletdamage[1] = currentSpall.shellType.bulletdamage[1] * spallingSizeCoef
		currentSpall.shellType.bulletdamage[2] = currentSpall.shellType.bulletdamage[2] * spallingSizeCoef
		currentSpall.shellType.bulletdamage[3] = currentSpall.shellType.bulletdamage[3] * spallingSizeCoef
		currentSpall.shellType.caliber = currentSpall.shellType.caliber * spallingSizeCoef
		currentSpall.shellType.shellWidth = currentSpall.shellType.shellHeight * spallingSizeCoef 
		currentSpall.shellType.shellHeight = currentSpall.shellType.shellHeight * spallingSizeCoef
		currentSpall.penDepth = (currentSpall.shellType.maxPenDepth/2)*spallingSizeCoef
		if(globalConfig.penCheck>=currentSpall.shellType.maxPenDepth)then
			currentSpall.maxChecks  =1
		else
			currentSpall.maxChecks = currentSpall.shellType.maxPenDepth/globalConfig.penCheck
		end
		-- currentSpall.maxChecks  =2

		currentSpall.shellType.r = 1 + (math.random(0,5)/10)
		currentSpall.shellType.g = 0.7 + (math.random(0,5)/10)
		currentSpall.shellType.b = 1


		spallHandler.shellNum = (spallHandler.shellNum%#spallHandler.shells) +1
	end
	-- DebugPrint("test")

end

function popSpalling(shell,hitTarget)


		local penetration,passThrough,test,penDepth,dist,spallValue =  getProjectilePenetration(shell,hitTarget)
		-- shell.penDepth = shell.penDepth - penDepth

		local holeModifier = math.random(-15,15)/100




		local fireChance = math.random(0,100)/100
		local firethreshold = 0.9
		if(shell.shellType.payload) then
			if(shell.shellType.payload == "incendiary") then
				firethreshold = 0.6
			elseif(shell.shellType.payload == "HESH") then
					firethreshold = 0.8
			elseif(shell.shellType.payload == "HE-I") then
					firethreshold = 0.45
			elseif(shell.shellType.payload == "kinetic") then
					firethreshold = 0.7
			elseif(shell.shellType.payload == "AP") then
					firethreshold = 0.99
			end
			if(fireChance>firethreshold)then
				SpawnFire(shell.point1)
			end
			if shell.shellType.hit and shell.shellType.hit <3 then
				if(shell.shellType.hit ==1)then
					MakeHole(shell.point1,shell.shellType.bulletdamage[1]*1.4)
				else
					MakeHole(shell.point1,shell.shellType.bulletdamage[1]*1.4,shell.shellType.bulletdamage[2]*1.2)
				end

			else
				MakeHole(shell.point1,shell.shellType.bulletdamage[1]*1.4,shell.shellType.bulletdamage[2]*1.2, shell.shellType.bulletdamage[3]*1.2)
			end

			
			
		end

	if(shell.penDepth>0) then
		if shell.shellType.hit and shell.shellType.hit <3 then
			if(shell.shellType.hit ==1)then
				MakeHole(test.pos,shell.shellType.bulletdamage[1]*1.4)
			else
				MakeHole(test.pos,shell.shellType.bulletdamage[1]*1.4,shell.shellType.bulletdamage[2]*1.2)
			end
		else
			MakeHole(test.pos,shell.shellType.bulletdamage[1]*1.4,shell.shellType.bulletdamage[2]*1.2, shell.shellType.bulletdamage[3]*1.2)
		end
	
	else		
	-- 	Explosion(shell.point1)
		shell.active = false
		for key,val in ipairs( shell ) do 
			val = nil

		end
		shell = deepcopy(spallHandler.defaultShell)
	end

end

function spallingOperations(projectile,dt )
		projectile.cannonLoc.pos = projectile.point1
		local shellHeight = projectile.shellType.shellHeight
		local shellWidth = projectile.shellType.shellWidth
		local r = projectile.shellType.r
		local g = projectile.shellType.g
		local b = projectile.shellType.b


		--- sprite drawing
		DrawSprite(projectile.shellType.Spallingsprite, projectile.cannonLoc,projectile.shellType.shellWidth,shellHeight , r, g, b, 1, 0, false)
		local altloc = projectile.cannonLoc
		altloc.rot = QuatRotateQuat(altloc.rot,QuatEuler(0, 90,0))
		DrawSprite(projectile.shellType.Spallingsprite, altloc, projectile.shellType.shellWidth, shellHeight, r, g, b, 1, 0, false)
		altloc.rot = QuatRotateQuat(projectile.cannonLoc.rot,QuatEuler(90, 0,0))
		DrawSprite(projectile.shellType.Spallingsprite, altloc, projectile.shellType.shellWidth, projectile.shellType.shellWidth, r, g, b, 1, 0, false)
		


		---
		---

			--- PROJECTILE MOTION

		---


		---  ADDING DISPERSION
		local dispersion = Vec(math.random(-1,1)*projectile.dispersion,math.random(-1,1)*projectile.dispersion,math.random(-1,1)*projectile.dispersion)
		if(projectile.shellType.dispersionCoef) then
			dispersion=VecScale(dispersion,dispersionCoef)
		end
		projectile.predictedBulletVelocity = VecAdd(projectile.predictedBulletVelocity,(VecScale(dispersion,dt)))



		-- --- applying drag 
		-- local spallDrag = VecScale(
		-- 	VecSub(
		-- 		TransformToParentPoint(
		-- 			Transform(projectile.point1,projectile.cannonLoc.rot),
		-- 			Vec(0,0,50)),projectile.point1),
		-- 		dt)
		-- projectile.predictedBulletVelocity = VecAdd(projectile.predictedBulletVelocity,spallDrag)
		--- APPLYING GRAVITY
		-- if(projectile.shellType.gravityCoef) then
		-- 	local shellGravity = VecScale(globalConfig.gravity,projectile.shellType.gravityCoef)
		-- 	projectile.predictedBulletVelocity = VecAdd(projectile.predictedBulletVelocity,(VecScale(shellGravity,dt)))
		-- else

			projectile.predictedBulletVelocity = VecAdd(projectile.predictedBulletVelocity,(VecScale(globalConfig.gravity,dt)))
		-- end

	
		local point2 = VecAdd(projectile.point1,VecScale(projectile.predictedBulletVelocity,dt))
		QueryRequire("physical")
		local hit, dist1,norm1,shape1 = QueryRaycast(projectile.point1, VecNormalize(VecSub(point2,projectile.point1)),VecLength(VecSub(point2,projectile.point1)))
		
		projectile.cannonLoc.rot = QuatRotateQuat(QuatLookAt(point2,projectile.point1),QuatEuler(00, 90, 90))
		
			if(hit)then 
				hitPos = VecAdd(projectile.point1, VecScale(VecNormalize(VecSub(point2,projectile.point1)),dist1))
				projectile.point1 = hitPos
				 popSpalling(projectile,shape1)
				-- Explosion(hitPos,2)
			else
				projectile.point1 = point2
			end
		
end


function pushshrapnel(spallingLoc,spallShell,test,hitTarget)

	local spallValue = 10
	if(spallShell.shellType.explosionSize) then 
		spallValue = spallShell.shellType.explosionSize*5
	end
	local spallQuant = math.random(1,spallValue*3)
---			kinetic = 0.8,
			-- AP 		= 0.3,
			-- APHE    = 0.3,
			-- HESH 	= 2,
			-- HEI 	= 1,
	-- DebugPrint(spallValue)


	for i=1, spallQuant do 

		local spallingSizeCoef = math.random(1,4)/10
		if(spallShell.shellType.payload == "HESH")then
			spallingSizeCoef = spallingSizeCoef * globalConfig.spallFactor.HESH
		end

		-- test.rot = QuatLookAt(spallShell.lastPos,test)
		local spallPos = TransformCopy(test)
		-- spallPos.pos = TransformToParentPoint(spallPos, 0,-16,0)
		
		local direction = rndVec(math.random(1,spallValue))
		local point1 = spallPos.pos
					
		spallHandler.shells[spallHandler.shellNum] = deepcopy(spallHandler.defaultShell)
		local currentSpall 				= spallHandler.shells[spallHandler.shellNum] 
		currentSpall.active 			= true 
		currentSpall.shellType = deepcopy(spallShell.shellType) 
		currentSpall.cannonLoc 			= spallPos
		currentSpall.point1			= point1 
		currentSpall.predictedBulletVelocity = rndVec(math.random() * 25)
		currentSpall.shrapnel = true
		currentSpall.hitTarget = hitTarget
		-- currentSpall.predictedBulletVelocity = VecScale(
		-- 												VecAdd(
		-- 													VecScale(spallShell.predictedBulletVelocity,0.8),fwdPos),0.5)
		--VecScale(direction,currentSpall.shellType.velocity*.2)
		currentSpall.originPos 	  = spallPos 
		currentSpall.maxTimeToLive = (currentSpall.shellType.timeToLive *(spallingSizeCoef+0.2))*(math.random(50,100)/100)
		currentSpall.timeToLive	  = currentSpall.maxTimeToLive
		if(spallShell.dispersion) then 
			currentSpall.dispersion 	  = 20 
			else
			currentSpall.dispersion 	  = 10 
		end
		-- DebugPrint("velocity: "..VecStr(currentSpall.predictedBulletVelocity).."  | pos = "..VecStr(TransformToParentPoint(spallPos, 0,-16,0)).." | "..VecStr(test.pos))
		currentSpall.shellType.bulletdamage[1] = currentSpall.shellType.bulletdamage[1] * spallingSizeCoef
		currentSpall.shellType.bulletdamage[2] = currentSpall.shellType.bulletdamage[2] * spallingSizeCoef
		currentSpall.shellType.bulletdamage[3] = currentSpall.shellType.bulletdamage[3] * spallingSizeCoef
		currentSpall.shellType.caliber = (currentSpall.shellType.caliber * spallingSizeCoef)*0.3
		currentSpall.shellType.shellWidth = math.max(math.random() * (currentSpall.shellType.shellWidth * spallingSizeCoef),0.1 )
		currentSpall.shellType.shellHeight = math.max(math.random() * (currentSpall.shellType.shellWidth * spallingSizeCoef),0.1) 
		currentSpall.penDepth = (currentSpall.shellType.maxPenDepth/2)*spallingSizeCoef
		if(globalConfig.penCheck>=currentSpall.shellType.maxPenDepth)then
			currentSpall.maxChecks  =1
		else
			currentSpall.maxChecks = currentSpall.shellType.maxPenDepth/globalConfig.penCheck
		end
		-- currentSpall.maxChecks  =2

		currentSpall.shellType.r = 2 + (math.random(0,5)/10)
		currentSpall.shellType.g = 1.7 + (math.random(0,5)/10)
		currentSpall.shellType.b = 1 + (math.random(0,10)/10)


		spallHandler.shellNum = (spallHandler.shellNum%#spallHandler.shells) +1

	end
	-- DebugPrint("test")

end


function shrapnelOperations(projectile,dt )
		projectile.cannonLoc.pos = projectile.point1
		local shellHeight = projectile.shellType.shellHeight
		local shellWidth = projectile.shellType.shellWidth
		-- local spallDecay =  math.random()* (currentSpall.maxTimeToLive / currentSpall.timeToLive	)
		local spallDecay = math.random()
		local r = projectile.shellType.r * spallDecay
		local g = projectile.shellType.g * spallDecay
		local b = projectile.shellType.b * spallDecay


		--- sprite drawing
		DrawSprite(projectile.shellType.Spallingsprite, projectile.cannonLoc,projectile.shellType.shellWidth,shellHeight , r, g, b, 1, 0, false)
		local altloc = projectile.cannonLoc
		altloc.rot = QuatRotateQuat(altloc.rot,QuatEuler(0, 90,0))
		DrawSprite(projectile.shellType.Spallingsprite, altloc, projectile.shellType.shellWidth, shellHeight, r, g, b, 1, 0, false)
		altloc.rot = QuatRotateQuat(projectile.cannonLoc.rot,QuatEuler(90, 0,0))
		DrawSprite(projectile.shellType.Spallingsprite, altloc, projectile.shellType.shellWidth, projectile.shellType.shellWidth, r, g, b, 1, 0, false)
		


		---
		---

			--- PROJECTILE MOTION

		---


		---  ADDING DISPERSION
		local dispersion = Vec(math.random(-1,1)*projectile.dispersion,math.random(-1,1)*projectile.dispersion,math.random(-1,1)*projectile.dispersion)
		if(projectile.shellType.dispersionCoef) then
			dispersion=VecScale(dispersion,dispersionCoef)
		end
		projectile.predictedBulletVelocity = VecAdd(projectile.predictedBulletVelocity,(VecScale(dispersion,dt)))



		-- --- applying drag 
		-- local spallDrag = VecScale(
		-- 	VecSub(
		-- 		TransformToParentPoint(
		-- 			Transform(projectile.point1,projectile.cannonLoc.rot),
		-- 			Vec(0,0,50)),projectile.point1),
		-- 		dt)
		-- projectile.predictedBulletVelocity = VecAdd(projectile.predictedBulletVelocity,spallDrag)
		--- APPLYING GRAVITY
		-- if(projectile.shellType.gravityCoef) then
		-- 	local shellGravity = VecScale(globalConfig.gravity,projectile.shellType.gravityCoef)
		-- 	projectile.predictedBulletVelocity = VecAdd(projectile.predictedBulletVelocity,(VecScale(shellGravity,dt)))
		-- else

			projectile.predictedBulletVelocity = VecAdd(projectile.predictedBulletVelocity,(VecScale(globalConfig.gravity,dt)))
		-- end

	
		local point2 = VecAdd(projectile.point1,VecScale(projectile.predictedBulletVelocity,dt))
		QueryRequire("physical")
		local hit, dist1,norm1,shape1 = QueryRaycast(projectile.point1, VecNormalize(VecSub(point2,projectile.point1)),VecLength(VecSub(point2,projectile.point1)))
		
		projectile.cannonLoc.rot = QuatRotateQuat(QuatLookAt(point2,projectile.point1),QuatEuler(00, 90, 90))
		
			if(hit)then 
				hitPos = VecAdd(projectile.point1, VecScale(VecNormalize(VecSub(point2,projectile.point1)),dist1))
				projectile.point1 = hitPos
				 popSpalling(projectile,shape1)
				-- Explosion(hitPos,2)
			else
				projectile.point1 = point2
			end
		
end

function spallingTick(dt)
		if unexpected_condition then error() end
			local activeShells = 0
			for key,shell in ipairs( spallHandler.shells  )do
			 	if(shell.active)then
			 		if(shell.timeToLive > 0) then 
			 			if(shell.shrapnel) then 
			 				shrapnelOperations(shell,dt)
			 				
			 			else
				 			spallingOperations(shell,dt)
				 		end
			 			shell.timeToLive = shell.timeToLive - dt
			 		else
			 			shell.active = false
			 		end
			 	end
		end
end


-----



----

----- SHELL HANDLING

----


function pushShell(gun,t_hitPos,dist,t_distance,t_cannon,t_penDepth)
	-- utils.printStr("pushing shell")
	if(dist <=0)then
		dist = maxDist
	end

	artillaryHandler.shells[getShellNum()].active = true
	artillaryHandler.shells[getShellNum()].hitPos = t_hitPos
	artillaryHandler.shells[getShellNum()].timeToTarget = dist*shellSpeed
	artillaryHandler.shells[getShellNum()].shellType = gun.magazines[gun.loadedMagazine].CfgAmmo

	if(t_cannon) then
		
		artillaryHandler.shells[getShellNum()].distance = t_distance
		artillaryHandler.shells[getShellNum()].t_cannon = t_cannon
		if(not t_penDepth ) then
				artillaryHandler.shells[getShellNum()].penDepth = gun.magazines[gun.loadedMagazine].CfgAmmo.maxPenDepth
				if(globalConfig.penCheck>=gun.magazines[gun.loadedMagazine].CfgAmmo.maxPenDepth)then
					artillaryHandler.shells[getShellNum()].maxChecks  =1
				else
					artillaryHandler.shells[getShellNum()].maxChecks = gun.magazines[gun.loadedMagazine].CfgAmmo.maxPenDepth/globalConfig.penCheck
				end
				-- utils.printStr("1")
		end
		-- SetString("hud.notification",artillaryHandler.shells[getShellNum()].penetrations.."\n"..artillaryHandler.shells[getShellNum()].timeToTarget)
	-- utils.printStr("3")
	end

	if (t_penDepth) then
				
				artillaryHandler.shells[getShellNum()].penDepth = t_penDepth
				-- artillaryHandler.shells[getShellNum()].shellType.explosionSize =1.5

				-- utils.printStr(gun.explosionSize.." | "..t_penDepth.." | "..dist)
	end
	-- else
		artillaryHandler.shells[getShellNum()].explosionSize = artillaryHandler.shells[getShellNum()].shellType.explosionSize
	-- end

	incrementShellNum()
	-- utils.printStr(4)
end

function pushShell2(shell,t_hitPos,dist,t_distance,t_cannon)
	-- utils.printStr("pushing shell")
	if(dist <=0)then
		dist = maxDist
	end

	artillaryHandler.shells[getShellNum()].active = true
	artillaryHandler.shells[getShellNum()].hitPos = t_hitPos
	artillaryHandler.shells[getShellNum()].timeToTarget = dist*shellSpeed
	artillaryHandler.shells[getShellNum()].shellType = shell.shellType

	if(t_cannon) then
		
		artillaryHandler.shells[getShellNum()].distance = t_distance
		artillaryHandler.shells[getShellNum()].t_cannon = t_cannon
				artillaryHandler.shells[getShellNum()].penDepth = shell.penDepth

				artillaryHandler.shells[getShellNum()].maxChecks = shell.maxChecks
				artillaryHandler.shells[getShellNum()].explosionSize = artillaryHandler.shells[getShellNum()].shellType.explosionSize
				-- utils.printStr("1")
		-- SetString("hud.notification",artillaryHandler.shells[getShellNum()].penetrations.."\n"..artillaryHandler.shells[getShellNum()].timeToTarget)
	-- utils.printStr("3")
	end

	incrementShellNum()
	-- utils.printStr(4)
end

function popShell(shell)
	-- utils.printStr(1)
	if(shell.penDepth) then
		-- utils.printStr(2)
		-- utils.printStr(shell.penDepth)
		local penetration,passThrough,test,penDepth,dist =  getPenetration(shell) 
		-- utils.printStr(3)
		shell.penDepth = shell.penDepth - penDepth
		-- and shell.penetrations>0)
		-- utils.printStr(dist)
		if( passThrough and shell.penDepth>0) then
					
				if(shell.hitPos ~= nil)then
					-- utils.printStr(type(shell.hitPos))
					-- utils.printStr(utils.explodeTable(shell.hitPos).." "..shell.hitPos[1])
					-- utils.printLoc(shell.hitPos)

					Explosion(shell.hitPos,0.5)

					shellPenetration(shell,test,dist)
					-- utils.printStr(shell.penDepth)
					
				else
					utils.printStr("no shell hitPos")
				end


		else

			Explosion(test.pos,shell.explosionSize)
			-- utils.printStr("penetration  explosion")
		-- shellPenetration(shell)
		-- shell = deepcopy(artillaryHandler.defaultShell)
		end
	else
		-- utils.printStr("normal explosion")
		Explosion(shell.hitPos,shell.explosionSize)
	end
	shell.active = false
	shell = deepcopy(artillaryHandler.defaultShell)
end

function getShellNum()
	return artillaryHandler.shellNum
	
end

function incrementShellNum()
	artillaryHandler.shellNum = ((artillaryHandler.shellNum+1) % #artillaryHandler.shells)+1
end



function artillaryTick(dt)
	local activeShells = 0
		for key,shell in ipairs( artillaryHandler.shells  )do
			 if(shell.active==true)then
			 	if(type(shell.hitPos)~= "table")then
			 		shell.active = false
			 	else
				 	activeShells= activeShells+1
				 	if shell.timeToTarget <0 then
				 		popShell(shell)
				 	else
				 		shell.timeToTarget = shell.timeToTarget-dt
				 	end
			 	end
			 end
		end
	-- utils.printStr(activeShells)
end





 -- check left right, if number then explode, if 0 then fly on.
function getPenetration(shell)
	local cannonLoc = shell.t_cannon
	local penetration = false
	local passThrough = true  
	local test= cannonLoc	
	local outstring =""
	local penDepth =0
	local dist1 = 0
	local hit1=false
	local penDepth = 0
	for i =1,shell.maxChecks do 
		local fwdPos = TransformToParentPoint(test, Vec(0, globalConfig.penCheck * -1,0))
	    local direction = VecSub(fwdPos, test.pos)
	     -- printloc(direction)
	    direction = VecNormalize(direction)
	    QueryRequire("physical")
    	hit1, dist1 = QueryRaycast(test.pos, direction, maxDist)
	    	local tstStrn = ""
	    	-- if(dist1 == 0 and hit1) then
	    	-- 	tstStrn = ("penetrated")
	    	-- elseif (dist1 == 0 ) then
	    	-- 	tstStrn = ("passThrough")
	    	-- else
	    	-- 	tstStrn = ("penetrated + possible next penetration")
	    	-- end
	    	outstring= outstring.."check: "..i.." : "..dist1.." "..tstStrn.."\n"--.."\n1: "..dist2.."\n1.5: "..dist3)	
	    	-- utils.printStr("2_3_5 "..outstring)
		
		if(dist1>0)then
			penDepth = globalConfig.penCheck*i
			penetration=true
			break
		end
		test = rectifyPenetrationVal(test)
	end
	-- utils.printStr("2_4")
	-- utils.printStr(outstring)
	if(dist1 ==0) then

		passThrough = not hit1

		-- passThrough,checks = didPassThrough(cannonLoc)
		-- checks=""
		-- if(not passThrough) then
		-- 	printStr("hitWall, stuck in object\nPrimaryChecks:\n"..outstring.."\nReversechecks:\n"..checks.."\nDidn't pass Through")
		-- else
		-- 	printStr("PrimaryChecks:\n"..outstring.."\nReversechecks:\n"..checks.."\nPassed Through")
		-- end
	end
	return penetration,passThrough,test,penDepth,dist1
end

function shellPenetration(shell,cannonLoc,dist)

	if(dist == 0) then
		dist = maxDist
	end

		hitPos = TransformToParentPoint(cannonLoc, Vec(0, dist * -1,0))

      	p = cannonLoc.pos

		d = VecNormalize(VecSub(hitPos, p))
		spread = 0.03
		d[1] = d[1] + ((math.random()-0.5)*2*spread)*dist/shell.distance
		d[2] = d[2] + ((math.random()-0.5)*2*spread)*dist/shell.distance
		d[3] = d[3] + ((math.random()-0.5)*2*spread)*dist/shell.distance
		d = VecNormalize(d)
		p = VecAdd(p, VecScale(d, 0.1))
		
			if (dist<maxDist) then
				cannonLoc.pos = hitPos
				pushShell2(shell,hitPos,dist,(maxDist-dist),cannonLoc)
				-- pushShell(shell,hitPos,dist,(maxDist-dist),cannonLoc,shell.penDepth)
				--pushShell(gun,t_hitPos,dist,t_distance,t_cannon,t_penDepth)
			end
		-- utils.printStr("test")
		Shoot(p, d,0)
	

	-- body
end

function rectifyPenetrationVal(t_cannonLoc)
		-- utils.printStr("fixingpen")
	local y = 0
	local x = 0 
	local z = globalConfig.penCheck


	local fwdPos = TransformToParentPoint(t_cannonLoc, Vec(x, z,y))

	local direction = VecSub(fwdPos, t_cannonLoc.pos)

	t_cannonLoc.pos = VecAdd(t_cannonLoc.pos, direction)
	return t_cannonLoc
end

function rectifyBarrelCoords(gun)
	local barrel = nil
	if(gun.multiBarrel)then
		-- gun.multiBarrel, barrel = next(gun.barrels,gun.multiBarrel)
		barrel = gun.barrels[gun.multiBarrel]
		gun.multiBarrel = (gun.multiBarrel%#gun.barrels)+1
	else 
		barrel = gun.barrels[1]
	end
	-- utils.printStr	(gun.multiBarrel)--.." | "..#gun.barrels	)
	local cannonLoc = GetShapeWorldTransform(gun.id)
	local y = barrel.y
	local x = barrel.x 
	local z = barrel.z
	local fwdPos = TransformToParentPoint(cannonLoc, Vec(x, z,y))
	local direction = VecSub(fwdPos, cannonLoc.pos)
	cannonLoc.pos = VecAdd(cannonLoc.pos, direction)
	return cannonLoc
end

function getBarrelCoords(gun)
	local barrel = nil
	if(gun.multiBarrel)then
		-- gun.multiBarrel, barrel = next(gun.barrels,gun.multiBarrel)
		barrel = gun.barrels[gun.multiBarrel]
	else 
		barrel = gun.barrels[1]
	end
	-- utils.printStr	(gun.multiBarrel)--.." | "..#gun.barrels	)
	local cannonLoc = GetShapeWorldTransform(gun.id)
	local y = barrel.y
	local x = barrel.x 
	local z = barrel.z
	local fwdPos = TransformToParentPoint(cannonLoc, Vec(x, z,y))
	local direction = VecSub(fwdPos, cannonLoc.pos)
	cannonLoc.pos = VecAdd(cannonLoc.pos, direction)
	return cannonLoc
end



function turretRotatation(turret,turretJoint)
	if unexpected_condition then error() end
	if(turret)then 
		if( turret.locked) then
			local targetRotation = lockedTurretAngle(turret)
				SetJointMotor(turretJoint, targetRotation)
		else

			local turret = turret.id
			local forward = turretAngle(0,1,0,turret)
			local back 	  = turretAngle(0,-1,0,turret) 
			local left 	  = turretAngle(-1,0,0,turret)
			local right   = turretAngle(1,0,0,turret)
			local up 	  = turretAngle(0,0,1,turret)
			local down 	  = turretAngle(0,0,-1,turret)
			-- SetString("hud.notification",
			-- 	"forward: "..
			-- 	forward..
			-- 	"\nback: "..
			-- 	back..
			-- 	"\nleft: "..
			-- 	left..
			-- 	"\nright: "..
			-- 	right)
			local bias = 0
			if(forward<(1-bias)) then
				if(left>right+bias) then
					SetJointMotor(turretJoint, 0.1+1*left)
				elseif(right>left+bias) then
					SetJointMotor(turretJoint, -.1+(-1*right))
				else
					SetJointMotor(turretJoint, 0)
				end
			else
				SetJointMotor(turretJoint, 0)
			end

		end
	end
end

function turretAngle(x,y,z,turret)

	local turretTransform = GetShapeWorldTransform(turret)
	local fwdPos = TransformToParentPoint(GetCameraTransform(), Vec(0, 0, 1000))
	local toPlayer = VecNormalize(VecSub(fwdPos, turretTransform.pos))
	local forward = TransformToParentVec(turretTransform, Vec(x,  y, Z))
	local orientationFactor = clamp(VecDot(forward, toPlayer) * 0.7 + 0.3, 0.0, 1.0)
	return orientationFactor
end

function gunAngle(x,y,z,gun,gunJoint)

	local targetAngle, dist = getTargetAngle(gun)

	

	-- targetAngle = targetAngle*verted
    -- SetString("hud.notification","target Angle: "..targetAngle.."\nDist: "..dist.."\nJoint at: "..GetJointMovement(gunJoint).."\n min"..gun.elevationMin.." max:"..gun.elevationMax)
    local bias = 0
    if(-GetJointMovement(gunJoint) < (targetAngle-bias)) then
			SetJointMotor(gunJoint, 1*bias)
	elseif(-GetJointMovement(gunJoint) > (targetAngle+bias)) then
			SetJointMotor(gunJoint, -1*bias)
	else
		SetJointMotor(gunJoint	, 0)
	end 

end


function autoGunAim(gun,barrelCoords)
	local turretPos = GetShapeWorldTransform(gun.id).pos -- cheej
	-- turretPos[2] = turretPos[3]
	local targetPos = GetCameraTransform().pos
	local dir = VecSub(targetPos,turretPos)
	dir = VecNormalize(dir)
	local tilt = VecAdd(turretPos,dir)
	local heightDiff = tilt[2] - turretPos[2]
	heightDiff = 0.3 - heightDiff
	heightDiff = math.max(-0.25,heightDiff)
	-- targetPos[2] = 0
	-- turretPos[2] = 0
	if(reticleWorldPos) then 
		targetPos = reticleWorldPos
	end
	shootDir = VecSub(turretPos,targetPos)
	shootDir = VecNormalize(shootDir)
	-- shootDir[2] = heightDiff
	shootDir = VecNormalize(shootDir)

	local lookDir =  VecAdd(turretPos,VecScale(shootDir,100))
	local nt = Transform()
	-- if(reticleWorldPos)then 
	-- 	DebugWatch("reticle world",reticleWorldPos)
		
	-- else
	-- 	DebugWatch("lookdir",lookDir)
	-- end

	-- DebugLine(turretPos,lookDir,0,0,1,1)
	nt.rot = QuatLookAt(turretPos, lookDir) -- cheej
	nt.pos = VecCopy(turretPos)
	nt = TransformToParentPoint(nt,Vec(0,0,-50))
	gunLaying(gun,barrelCoords,nt)
end

function gunLaying(gun,barrelCoords,targetPos)
	-- DebugWatch("targetPos",targetPos)
	local up = gunAngle(0,0,-1,gun,targetPos)
	local down = gunAngle(0,0,1	,gun,targetPos)
	local bias = 0.05
	gun.aimed = false

	-- DebugWatch("gun up: ",
	-- 		up)
	-- DebugWatch("gun down: ",
	-- 		down)

	local dir = 0
	if(up < down-bias*0.25)then  -- and up-bias*.5>0) then 
		dir = 1
	elseif(up > down+bias*0.25 )then  --and down-bias*.5>0) then
		dir = -1

	end 
	-- DebugWatch("dir",dir)
	SetJointMotor(gun.gunJoint, dir*(bias*10))
end

function gunAngle(x,y,z,gun,targetPos)

	 	-- DebugWatch("avf ai turret test ",1)
	local gunTransform = GetShapeWorldTransform(gun.id)
	 
	local fwdPos = targetPos

	-- DebugWatch("target",targetPos)

	-- DebugWatch("gunTransform.pos",gunTransform.pos)	
	---fwdPos = {fwdPos[1],fwdPos[3],fwdPos[2]}
	local toPlayer = VecNormalize(VecSub(gunTransform.pos,fwdPos))
	local forward = TransformToParentVec(gunTransform, Vec(x,  y, z))
	local orientationFactor = clamp(VecDot(forward, toPlayer) * 0.7 + 0.3, 0.0, 1.0)
	-- DebugLine(gunTransform.pos,fwdPos,1,0,0,1)

	return orientationFactor
end

function lockGun(gun)
	gun.lockedAngle =  GetJointMovement(gun.gunJoint)
end
function lockTurret(turret)
	turret.lockedAngle =  GetJointMovement(turret.turretJoint)
end

function lockedTurretAngle(turret)
	

	-- targetAngle = targetAngle*verted
    -- SetString("hud.notification","target Angle: "..targetAngle.."\nDist: "..dist.."\nJoint at: "..GetJointMovement(gunJoint).."\n min"..gun.elevationMin.." max:"..gun.elevationMax)
    local turretMovement = 0
    if(GetJointMovement(turret.turretJoint) > turret.lockedAngle) then
			turretMovement = 1
	elseif(GetJointMovement(turret.turretJoint) < turret.lockedAngle) then
			turretMovement = -1
	end 
	return turretMovement

end


function lockedGunAngle(gun)
	

	-- targetAngle = targetAngle*verted
    -- SetString("hud.notification","target Angle: "..targetAngle.."\nDist: "..dist.."\nJoint at: "..GetJointMovement(gunJoint).."\n min"..gun.elevationMin.." max:"..gun.elevationMax)
    local gunMovement = 0
    if(GetJointMovement(gun.gunJoint) > gun.lockedAngle) then
			gunMovement = 1
	elseif(GetJointMovement(gun.gunJoint) < gun.lockedAngle) then
			gunMovement = -1
	end 
	return gunMovement

end



function getTargetAngle(gun )
	 	local gunTransform =	GetShapeWorldTransform(GetJointOtherShape(gun.gunJoint,gun.id))
		gunTransform.pos = AabbGetShapeCenterPos(GetJointOtherShape(gun.gunJoint,gun.id))
		  -- GetCameraTransform()
		 -- gunTransform.pos[2] = 20- gunTransform.pos[2]
		-- gunTransform =  GetShapeWorldTransform(vehicle.turret)
		-- gunTransform.pos[2] = gunTransform.pos[2] 
		-- gunTransform.rot = camTransform.rot
		local verted	 = -1.2
		local fwdPos = TransformToParentPoint(gunTransform, Vec(0,maxDist *-1 ,0))
	    local direction = VecSub(fwdPos, gunTransform.pos)
	     -- printloc(direction)
	    direction = VecNormalize(direction)
    	QueryRejectBody(vehicle.body)
	-- QueryRejectBody(gun.id)
		QueryRequire("physical")
	    local hit, dist = QueryRaycast(gunTransform.pos, direction, maxDist)

		-- outerReticleScreenPos = 
		-- TransformToParentPoint(gunTransform, )



	    if(dist == 0)then
	    	dist = maxDist
	    end
    	targetAngle =  (dist*gun.rangeCalc)
    	if(gun.gunBias)then 
    		targetAngle = targetAngle+gun.gunBias
    	end
		-- targetAngle	=targetAngle	-5
		return targetAngle,dist
end


--Return a random vector of desired length
function rndVec(length)
	local v = VecNormalize(Vec(math.random(-100,100), math.random(-100,100), math.random(-100,100)))
	return VecScale(v, length)	
end


function rnd(mi, ma)
	return math.random(1000)/1000*(ma-mi) + mi
end

function getPlayerShootInput()
	if InputPressed(armedVehicleControls.fire) or InputDown(armedVehicleControls.fire) then
	 
		return true
	elseif(InputReleased(armedVehicleControls.fire)) then
		
		return false,true 
	else
		return false
	end
	
end



function getPlayerInteactInput()
	if InputPressed("interact") or InputDown("interact") then
	 
		return true
	elseif(InputReleased("interact")) then
		
		return false,true 
	else
		return false
	end
	
end

function getPlayerGrabInput()
	if InputPressed("rmb") or InputDown("rmb") then
	 
		return true
	elseif(InputReleased("rmb")) then
		
		return false,true 
	else
		return false
	end
	
end

function getPlayerMouseDown()
	if not InputPressed(armedVehicleControls.fire) and InputDown(armedVehicleControls.fire) then
		return true

	else
		return false
	end
end

function getInteractMouseDown()
	if not InputPressed("interact") and InputDown("interact") then
		return true

	else
		return false
	end
end


function ammoRefillTick(dt)
	
	local inVehicle,index = playerInVehicle()
	if(inVehicle) then
		for key,stockpile in pairs(ammoContainers.crates) do
			-- utils.printStr("vehicle not in region")
			if(IsVehicleInTrigger(stockpile,vehicles[index].vehicle.id))then
				ammoContainers.refillTimer = ammoContainers.refillTimer +dt
				if(ammoContainers.refillTimer>2) then
					local reloaded = refillAmmo(dt)
					if(reloaded > 0) then 
						PlaySound(ammoRefillSound, GetVehicleTransform(vehicle.id).pos, 5)
					end
					ammoContainers.refillTimer = 0
				end
			end

		end
	end
end

function refillAmmo(dt)
	local reloaded = 0
	local count = 0
	local teststr = ""
	for key,gunGroup in pairs(vehicleFeatures.weapons) do
		for key2,gun in ipairs(gunGroup) do
			for magazine,loadedMagazine in pairs(gun.magazines) do 
				count = count +1
				local currentMagazine =loadedMagazine.magazinesAmmo[loadedMagazine.currentMagazine]
				if(currentMagazine.expendedMagazines>0) then
					reloaded = reloaded +1
					currentMagazine.expendedMagazines = currentMagazine.expendedMagazines-1 
					if(loadedMagazine.outOfAmmo) then
						loadedMagazine.ammoCount = loadedMagazine.magazineCapacity
						loadedMagazine.outOfAmmo = false		
					end
				end
			end

		end
	end
	return reloaded
	-- utils.printStr("total mags: "..count.."\nReloaded: "..reloaded)
end

function handleInputs(dt)
	if unexpected_condition then error() end
	if(InputPressed(armedVehicleControls.deploySmoke))then
		for i=1,#vehicleFeatures.utility.smoke do
			if(not vehicleFeatures.utility.smoke[i].reloading) then
				smokeProjection(vehicleFeatures.utility.smoke[i])
			end
		end
	end 
	if(InputPressed(armedVehicleControls.changeWeapons))then 
		local tstStrn=""

		vehicleFeatures.currentGroup = (vehicleFeatures.currentGroup%#vehicleFeatures.validGroups)+1
		vehicleFeatures.equippedGroup = vehicleFeatures.validGroups[vehicleFeatures.currentGroup]
		-- utils.printStr(#vehicleFeatures.weapons.secondary.."\ntest string ="..tstStrn)
		-- utils.printStr(vehicleFeatures.equippedGroup.." equipped!")--.."\n"..tstStrn.." | "..vehicleFeatures.currentGroup..vehicleFeatures.validGroups[vehicleFeatures.currentGroup])
	end
	if(InputPressed(armedVehicleControls.changeAmmunition))then 
		for key2,gun in ipairs(vehicleFeatures.weapons[vehicleFeatures.equippedGroup]) do

				gun.loadedMagazine =  ((gun.loadedMagazine)%#gun.magazines)+1
				-- utils.printStr(gun.magazines[gun.loadedMagazine].name.." equipped!")
			end
		
	end
	if(InputPressed(armedVehicleControls.lockRotation))then 
		for key,turretGroup in pairs(vehicleFeatures.turrets) do
			for key2,turret in ipairs(turretGroup) do
				if(turret.locked) then
					utils.printStr("UNLOCKING TURRET")
					turret.locked = nil
				else
					utils.printStr("LOCKING TURRET")
					turret.locked = true
					lockTurret(turret)
				end

				
			end
		end 	
	end

	if InputPressed(armedVehicleControls.lockAngle) then
		local gunGroup = vehicleFeatures.weapons[vehicleFeatures.equippedGroup]
		for key2,gun in ipairs(gunGroup) do
			if(not IsJointBroken(gun.gunJoint))then	
				if(gun.locked) then
					utils.printStr("UNLOCKING GUN")
					gun.locked = nil
				else
					utils.printStr("LOCKING GUN")
					gun.locked = true
					lockGun(gun)
				end
			end
		end
	end

	if((InputPressed(armedVehicleControls.sniperMode))) then
		-- DebugPrint("changing sniper mode")
		vehicle.sniperMode = not vehicle.sniperMode
	end


	handleLightOperation()

		-- local k,v = next(vehicleFeatures.weapons,nil)
		-- utils.printStr(k)
end


function playerInVehicle()

	local inVehicle = false
	local currentVehicle = 0
	local playerVehicle = GetPlayerVehicle()
	
	for key,vehicle in pairs(vehicles) do
		-- utils.printStr(vehicles[key].vehicleFeatures.weapons.primary[1].name)
		-- utils.printStr(vehicle.vehicle.id.." | "..playerVehicle) 
		if(vehicle.vehicle.id == playerVehicle) then 

			
			currentVehicle = key
			inVehicle = true
		end
	end
	return inVehicle,currentVehicle 
end

function addGun(gunJoint,attatchedShape,turretJoint)

	local gun = GetJointOtherShape(gunJoint, attatchedShape)
	local val3 = GetTagValue(gun, "component")
	local weaponType = GetTagValue(gun, "weaponType")
	local min, max = GetJointLimits(gunJoint)
	local group = GetTagValue(gun, "group")


	-- if(debugMode) then
	-- 	DebugPrint(weaponType.." | "..gunJoint.." | "..group.." | vehicle: "..vehicle.id)
	-- end
	if(group=="" or weaponType=="" or not IsHandleValid(gun)) then
		DebugPrint("error in config")
		return "false"

	end

	SetTag(gun, "AVF_Parent", vehicle.groupIndex )

	-- if(group=="" or weaponType=="") then
	-- 	return "false"
	-- end
	local index = (#vehicleFeatures.weapons[group])+1
	-- printStr(index)
	vehicleFeatures.weapons[group][index] = deepcopy(weapons[weaponType])
	vehicleFeatures.weapons[group][index].id = gun

	local status,retVal = pcall(gunCustomization,(vehicleFeatures.weapons[group][index]));
	if status then 
		-- DebugPrint("no errors")
	else
		DebugPrint(retVal)
	end
	-- gunCustomization(vehicleFeatures.weapons[group][index])

	status,retVal = pcall(loadShells,(vehicleFeatures.weapons[group][index]));
	if status then 
		-- utils.printStr("no errors")
	else
		DebugPrint(retVal)
		errorMessages = errorMessages..retVal.."\n"
	end

	-- loadShells(vehicleFeatures.weapons[group][index])

	if(turretJoint) then
		vehicleFeatures.weapons[group][index].turretJoint = turretJoint
	end

	vehicleFeatures.weapons[group][index].gunJoint = gunJoint
	vehicleFeatures.weapons[group][index].elevationMin = -min
	vehicleFeatures.weapons[group][index].elevationMax = -max
	vehicleFeatures.weapons[group][index].rangeCalc = (-max-min) / vehicleFeatures.weapons[group][index].gunRange
	
	-- removed tags for weapons for the time being


		SetTag(gun,"interact",vehicleFeatures.weapons[group][index].name)
	
	-- RemoveTag(gun,"interact")
	vehicleFeatures.weapons[group][index].reloading = false
	vehicleFeatures.weapons[group][index].ammo = 0			
	vehicleFeatures.weapons[group][index].currentReload = 0
	vehicleFeatures.weapons[group][index].timeToFire = 0
	vehicleFeatures.weapons[group][index].cycleTime = 60 / vehicleFeatures.weapons[group][index].RPM 


	if(not vehicleFeatures.weapons[group][index].elevationSpeed) then
		vehicleFeatures.weapons[group][index].elevationSpeed = 1
	end

	if (not vehicleFeatures.weapons[group][index].sight[1].bias)then
		vehicleFeatures.weapons[group][index].sight[1].bias = 1
	end

	if(vehicleFeatures.weapons[group][index].soundFile)then
		vehicleFeatures.weapons[group][index].sound = LoadSound(vehicleFeatures.weapons[group][index].soundFile)
	end
	if(vehicleFeatures.weapons[group][index].mouseDownSoundFile)then
		vehicleFeatures.weapons[group][index].mouseDownSound = LoadSound(vehicleFeatures.weapons[group][index].mouseDownSoundFile)
	end
	if(vehicleFeatures.weapons[group][index].loopSoundFile)then
		vehicleFeatures.weapons[group][index].loopSoundFile = LoadLoop(vehicleFeatures.weapons[group][index].loopSoundFile)
	end
	if(vehicleFeatures.weapons[group][index].tailOffSound)then
		vehicleFeatures.weapons[group][index].tailOffSound = LoadSound(vehicleFeatures.weapons[group][index].tailOffSound)
		vehicleFeatures.weapons[group][index].rapidFire = false
	end
	if(vehicleFeatures.weapons[group][index].reloadSound and vehicleFeatures.weapons[group][index].reloadPlayOnce)then
		vehicleFeatures.weapons[group][index].reloadSound = LoadSound(vehicleFeatures.weapons[group][index].reloadSound)
	elseif(vehicleFeatures.weapons[group][index].reloadSound) then
		vehicleFeatures.weapons[group][index].reloadSound = LoadLoop(vehicleFeatures.weapons[group][index].reloadSound)
	else
		vehicleFeatures.weapons[group][index].reloadSound = LoadLoop(weaponDefaults.reloadSound)
	end
	vehicleFeatures.weapons[group][index].dryFire =  LoadSound("MOD/sounds/dryFire0.ogg")

	-- if(weaponType~="2A46M")then
	-- 	utils.printStr(weaponType.." | "..vehicleFeatures.weapons[group][index].name.." | "..group)
	
	-- end


	if(HasTag(gun,"commander")) then
		 vehicleFeatures.commanderPos = gun
	end

	if HasTag(gun,"coax")then
		addCoax(gunJoint,attatchedShape,turretJoint)

	end

	addSearchlights(gun)

	vehicle.shapes[#vehicle.shapes+1] = gun

	return "gun: "..index.." "..#vehicleFeatures.weapons[group].."\n"..min.." | "..max.." "..vehicleFeatures.weapons[group][index].name.." "..gun.." "..vehicleFeatures.weapons[group][index].id.."\n"
end

function addCoax(gunJoint,attatchedShape,turretJoint)


	-- DebugPrint("ADDING COAX")

	local gun = GetJointOtherShape(gunJoint, attatchedShape)
	local val3 = GetTagValue(gun, "component")
	local weaponType = GetTagValue(gun, "coax")
	local min, max = GetJointLimits(gunJoint)
	local group = "coax"


	-- if(debugMode) then
	-- 	DebugPrint(weaponType.." | "..gunJoint.." | "..group.." | vehicle: "..vehicle.id)
	-- end
	if(group=="" or weaponType=="" or not IsHandleValid(gun)) then
		DebugPrint("error in config")
		return "false"

	end

	local index = (#vehicleFeatures.weapons[group])+1
	vehicleFeatures.weapons[group][index] = deepcopy(weapons[weaponType])
	vehicleFeatures.weapons[group][index].id = gun

	gunCustomization(vehicleFeatures.weapons[group][index],true)

	loadShells(vehicleFeatures.weapons[group][index],true)

	if(turretJoint) then
		vehicleFeatures.weapons[group][index].turretJoint = turretJoint
	end

	vehicleFeatures.weapons[group][index].gunJoint = gunJoint
	vehicleFeatures.weapons[group][index].elevationMin = -min
	vehicleFeatures.weapons[group][index].elevationMax = -max
	vehicleFeatures.weapons[group][index].rangeCalc = (-max-min) / vehicleFeatures.weapons[group][index].gunRange
	vehicleFeatures.weapons[group][index].reloading = false
	vehicleFeatures.weapons[group][index].ammo = 0			
	vehicleFeatures.weapons[group][index].currentReload = 0
	vehicleFeatures.weapons[group][index].timeToFire = 0
	vehicleFeatures.weapons[group][index].cycleTime = 60 / vehicleFeatures.weapons[group][index].RPM 
	if(not vehicleFeatures.weapons[group][index].elevationSpeed) then
		vehicleFeatures.weapons[group][index].elevationSpeed = 1
	end
	if (not vehicleFeatures.weapons[group][index].sight[1].bias)then
		vehicleFeatures.weapons[group][index].sight[1].bias = 1
	end
	if(vehicleFeatures.weapons[group][index].soundFile)then
		vehicleFeatures.weapons[group][index].sound = LoadSound(vehicleFeatures.weapons[group][index].soundFile)
	end
	if(vehicleFeatures.weapons[group][index].mouseDownSoundFile)then
		vehicleFeatures.weapons[group][index].mouseDownSound = LoadSound(vehicleFeatures.weapons[group][index].mouseDownSoundFile)
	end
	if(vehicleFeatures.weapons[group][index].loopSoundFile)then
		vehicleFeatures.weapons[group][index].loopSoundFile = LoadLoop(vehicleFeatures.weapons[group][index].loopSoundFile)
	end
	if(vehicleFeatures.weapons[group][index].tailOffSound)then
		vehicleFeatures.weapons[group][index].tailOffSound = LoadSound(vehicleFeatures.weapons[group][index].tailOffSound)
		vehicleFeatures.weapons[group][index].rapidFire = false
	end
	if(vehicleFeatures.weapons[group][index].reloadSound and vehicleFeatures.weapons[group][index].reloadPlayOnce)then
		vehicleFeatures.weapons[group][index].reloadSound = LoadSound(vehicleFeatures.weapons[group][index].reloadSound)
	elseif(vehicleFeatures.weapons[group][index].reloadSound) then
		vehicleFeatures.weapons[group][index].reloadSound = LoadLoop(vehicleFeatures.weapons[group][index].reloadSound)
	else
		vehicleFeatures.weapons[group][index].reloadSound = LoadLoop(weaponDefaults.reloadSound)
	end
	vehicleFeatures.weapons[group][index].dryFire =  LoadSound("MOD/sounds/dryFire0.ogg")



	-- DebugPrint("added gun")
end

function gunCustomization(gun,coax)
	if unexpected_condition then error() end
	
	for key,val in pairs(weaponOverrides) do 
		if(coax)then
			key = key.."coax"
		end
		-- DebugPrint(key)
		if(HasTag(gun.id,"@"..key) ) then
			-- DebugPrint(key)
			if(type(val)== 'table') then
				local subKeyItems = 50
				if(key == "backBlast") then
					subKeyItems = #gun.barrels
				end

				for i =1,subKeyItems do---#gun[key] do

					
					for subKey,subVal in pairs(val) do

						if(HasTag(gun.id,"@"..key..i..subVal)  ) then


							if(i>#gun[key]) then 
								i = #gun[key]+1
								gun[key][i] = deepcopy(gun[key][1])
								
							end
							local gunPart = gun[key][i] 
							-- DebugPrint( " | "..key..i..subVal)
							-- local teststr = key..i..subKey.." | "..gunPart[subKey]
							gunPart[subKey] = GetTagValue(gun.id,"@"..key..i..subVal)
							-- DebugPrint( GetTagValue(gun.id,"@"..key..i..subVal).." | "..key..i..subVal)
							-- DebugPrint(""..teststr.." | ".."test: "..gunPart[subKey].."\n")
						elseif(key == "backBlast" and #gun.backBlast>0) then
							gun.backblast[#gun.backblast+1] = deepcopy(gun.backblast[1])
						end
					end
				end
			else
				local tagValue = GetTagValue(gun.id,"@"..val)
				if tonumber(tagValue) ~= nil then
					tagValue = tonumber(tagValue)
				elseif(tagValue=="true") then
						tagValue = true
				elseif(tagValue=="false") then
					tagValue = false
				end;
				gun[key] = tagValue--GetTagValue(gun.id,"@"..val)
			end
		end
	end
	-- body
end

function loadShells(gun,coax)
	local gunMagazines = #gun.magazines
	-- DebugPrint(gunMagazines)
	for i=1,50 do
		if(i>#gun.magazines and HasTag(gun.id,"@magazine"..i.."_name")) then 
			local index = #gun.magazines+1
			gun.magazines[index] = deepcopy(gun.magazines[1])
			
		end
	end
	-- DebugPrint(#gun.magazines)
	gunMagazines = #gun.magazines
-- deepcopy(weapons[weaponType])
	for i =1,gunMagazines do
		gun.magazines[i].CfgAmmo = deepcopy(munitions[gun.magazines[i].name])
		if (gun.magazines[i].CfgAmmo.shellSpriteRearName )then 
			gun.magazines[i].CfgAmmo.spriteRear = LoadSprite(gun.magazines[i].CfgAmmo.shellSpriteRearName)
		else
			gun.magazines[i].CfgAmmo.spriteRear = LoadSprite("MOD/gfx/shellRear2.png")
		end

		if(gun.magazines[i].CfgAmmo.shellSpriteName ) then 
			gun.magazines[i].CfgAmmo.sprite = LoadSprite(gun.magazines[i].CfgAmmo.shellSpriteName)
		else
			gun.magazines[i].CfgAmmo.sprite = LoadSprite("MOD/gfx/shellModel2.png")
		end

		if(gun.magazines[i].CfgAmmo.spallingSpriteName) then
			gun.magazines[i].CfgAmmo.Spallingsprite = LoadSprite(gun.magazines[i].CfgAmmo.spallingSpriteName)
		else
			gun.magazines[i].CfgAmmo.Spallingsprite = LoadSprite("MOD/gfx/spalling.png")
		end
-- AmmoOverrides = {
-- 	name				= "name",	
-- 	magazineCapacity   	= "magazineCapacity",
-- 	magazineCount    	= "magazineCount",
-- 	explosionSize		= "explosionSize",
-- 	maxPenDepth			= "maxPenDepth",

		for key,val in pairs(AmmoOverrides) do 
			if(coax)then
				key = key.."coax"
			end
			if(HasTag(gun.id,"@magazine"..i.."_"..key) ) then
				if(utils.contains(gun.magazines[i],key)) then
					if(key =="name") then 
						gun.magazines[i].CfgAmmo.name = GetTagValue(gun.id,"@magazine"..i.."_name")  
						gun.magazines[i].name = gun.magazines[i].CfgAmmo.name	
					else
						local tagValue = GetTagValue(gun.id,"@magazine"..i.."_"..val)
						if tonumber(tagValue) ~= nil then
   								tagValue = tonumber(tagValue)
   						elseif(tagValue=="true") then
   							tagValue = true
						elseif(tagValue=="false") then
							tagValue = false
						end;
						gun.magazines[i][key] = tagValue	
					end
				else

					local tagValue = GetTagValue(gun.id,"@magazine"..i.."_"..val)
						if tonumber(tagValue) ~= nil then
   								tagValue = tonumber(tagValue)
   						elseif(tagValue=="true") then
   							tagValue = true
						elseif(tagValue=="false") then
							tagValue = false
						end;
						gun.magazines[i].CfgAmmo[key] = tagValue
				end
			end
		end


		

		if((gun.magazines[i].CfgAmmo.flightLoop)) then
			gun.magazines[i].CfgAmmo.flightLoopSound = LoadLoop(gun.magazines[i].CfgAmmo.flightLoop)
		end


		local modifier = math.log(gun.magazines[i].CfgAmmo.caliber)/10
		-- DebugPrint(modifier)
		gun.magazines[i].CfgAmmo.bulletdamage = {
							[1] = modifier*1.3,
							[2] = modifier*1,
							[3] = modifier*0.5
						}

		--- add penetration modifiers
		local penModifier = 1
		if( penetrationModifiers[gun.magazines[i].CfgAmmo.payload]) then 
			penModifier = penetrationModifiers[gun.magazines[i].CfgAmmo.payload]
		end
		gun.magazines[i].CfgAmmo.penModifier = penModifier


		if(gun.magazines[i].CfgAmmo.hit and gun.magazines[i].CfgAmmo.hit ==3) then
			gun.magazines[i].CfgAmmo.bulletdamage[3] = gun.magazines[i].CfgAmmo.bulletdamage[3] *.5 
		end

		-- if(i==1) then
			-- utils.printStr("@shell"..i.."_name")


			-- if(HasTag(gun.id,"@magazine"..i.."_name")) then 
			-- 	gun.magazines[i].CfgAmmo.name = GetTagValue(gun.id,"@magazine"..i.."_name")  
			-- 	gun.magazines[i].name = gun.magazines[i].CfgAmmo.name
			-- end
			-- if(HasTag(gun.id,"@magazine"..i.."_explosionSize")) then 
			-- 	gun.magazines[i].CfgAmmo.explosionSize = GetTagValue(gun.id,"@magazine"..i.."_explosionSize")  
			-- end
			-- if(HasTag(gun.id,"@magazine"..i.."_maxPenDepth")) then 
			-- 	gun.magazines[i].CfgAmmo.maxPenDepth = tonumber(GetTagValue(gun.id,"@magazine"..i.."_maxPenDepth"))  
			-- end
			-- if(HasTag(gun.id,"@magazine"..i.."_".."magazineCapacity")) then 
			-- 	gun.magazines[i].magazineCapacity = GetTagValue(gun.id,"@magazine"..i.."_magazineCapacity")  
			-- end
			-- if(HasTag(gun.id,"@magazine"..i.."_".."magazineCount")) then 
			-- 	gun.magazines[i].magazineCount = GetTagValue(gun.id,"@magazine"..i.."_magazineCount")  
			-- end
			gun.magazines[i].currentMagazine = 1
			gun.magazines[i].outOfAmmo = false
			gun.magazines[i].magazinesAmmo = {}
			for j = 1,gun.magazines[i].magazineCount do 

				gun.magazines[i].magazinesAmmo[j] = deepcopy(ammoDefaults.defaultMagazine)
				gun.magazines[i].magazinesAmmo[j].ammoName = gun.magazines[i].name
				gun.magazines[i].magazinesAmmo[j].magazineCapacity = gun.magazines[i].magazineCapacity
				gun.magazines[i].magazinesAmmo[j].AmmoCount 	= gun.magazines[i].magazineCapacity
				gun.magazines[i].magazinesAmmo[j].expendedMagazines 	= 0
				if(gun.magazines[i].magazinesAmmo[j].AmmoCount ==0) then 
					gun.magazines[i].magazinesAmmo[j].isEmpty = true
				else
					gun.magazines[i].magazinesAmmo[j].isEmpty = false
				end
				
			end


	-- 			ammoDefaults = {
	-- 	defaultMagazine = {
	-- 		ammoName = "",
	-- 		magazineCapacity = 0,
	-- 		AmmoCount = 0,
	-- 		isEmpty = true

	-- },

		-- end
	end
-- munitions[gun.magazines[gun.loadedMagazine].name]


end

function addSearchlights(object)
	local objectLights= GetShapeLights(object)
	if(objectLights) then 
		for i=1,#objectLights do
			vehicle.lights[#vehicle.lights+1] = objectLights[i]
		end
	end
end

function addSmokeLauncher(object)
		local launcherName = GetTagValue(object, "smokeLauncher")

		local launcherConfig = deepcopy(weapons[launcherName])

		local group = GetTagValue(object, "group")
	-- utils.printStr(group)

		local index = (#vehicleFeatures.utility[group])+1
		
		vehicleFeatures.utility[group][index] = launcherConfig

		vehicleFeatures.utility[group][index].id = object
		vehicleFeatures.utility[group][index].reloading = false
		vehicleFeatures.utility[group][index].currentReload = 0
		
end

function traverseTurret(turretJoint,attatchedShape)
	local outString = ""
	local turret = GetJointOtherShape(turretJoint, attatchedShape)
	local joints = GetShapeJoints(turret)
	local group  = GetTagValue(turret, "turretGroup")
	if (not group or group=="") then 
		group = "mainTurret"
	end
	local idNo   = (#vehicleFeatures.turrets[group])+1
	vehicleFeatures.turrets[group][idNo] = {}
	vehicleFeatures.turrets[group][idNo].id 	= turret
	vehicleFeatures.turrets[group][idNo].turretJoint  = turretJoint	
	for j=1,#joints do 
		if(joints[j]~=turretJoint)then
			local val2 = GetTagValue(joints[j], "component")
			if val2=="gunJoint" then
				outString = outString..addGun(joints[j], turret,turretJoint)
			end
		end
	end
	if(HasTag(turret,"smokeLauncher")) then

		addSmokeLauncher(turret)

	end
	if(HasTag(turret,"commander")) then
		 vehicleFeatures.commanderPos = turret
		end

	addSearchlights(turret)

	vehicle.shapes[#vehicle.shapes+1] = turret

	return outString

end

function pollNewVehicle(dt)
	-- if GetBool("savegame.mod.newVehicle") then
		addVehicle()

	-- 	SetBool("savegame.mod.newVehicle",false)
	-- end

end

function addVehicle()
	local sceneVehicles = FindVehicles("AVF_Custom",true)
	--utils.printStr(#sceneVehicles)

	for i = 1,#sceneVehicles do 
		if(GetTagValue(sceneVehicles[i], "AVF_Custom")=="unset" and
			GetTagValue(sceneVehicles[i], "cfg") == "vehicle" ) then

			local index = #vehicles +1
			vehicles[index] = {
							vehicle ={
									id = sceneVehicles[i],
									groupIndex = index,
									},
							vehicleFeatures = deepcopy(defaultVehicleFeatures),
							}
			vehicle = vehicles[index].vehicle
			vehicleFeatures = vehicles[index].vehicleFeatures
			initVehicle(vehicles[index])

			SetTag(sceneVehicles[i],"AVF_Custom","set")
			-- RemoveTag(sceneVehicles[i],"AVF_Custom")
		end
	end

end



--- taken from evertide mall tank script 
function drawReticleSprite(t)
	t.rot = QuatLookAt(t.pos, GetCameraTransform().pos)
	-- t.rot = QuatLookAt(t.pos, GetBodyTransform(body).pos)
	local tr = QuatEuler(0,0,GetTime()*60)
	t.rot = QuatRotateQuat(t.rot,tr)

	local size = 1.2

	DrawSprite(reticle1, t, size, size, .5, 0, 0, 1, false, false)
	DrawSprite(reticle1, t, size, size, .5, 0, 0, 1, true, false)

	local tr = QuatEuler(0,0,GetTime()*-80)
	t.rot = QuatRotateQuat(t.rot,tr)
	
	DrawSprite(reticle2, t, size, size, .5, 0, 0, 1, false, false)
	DrawSprite(reticle2, t, size, size, .5, 0, 0, 1, true, false)
	
	local tr = QuatEuler(0,0,GetTime()*100)
	t.rot = QuatRotateQuat(t.rot,tr)

	DrawSprite(reticle3, t, size, size, .5, 0, 0, 1, false, false)
	DrawSprite(reticle3, t, size, size, .5, 0, 0, 1, true, false)
end



function draw()



	local visible	 = 1
	--Only draw speedometer if visible
	if(playerInVehicle()and not viewingMap) then
		local gunGroup = vehicleFeatures.weapons[vehicleFeatures.equippedGroup]
		UiPush()
			if(vehicle.sniperMode)then
				for key,gun in pairs(gunGroup)	do 
					drawWeaponReticles(gun)	
				end
		end
		UiPop()
		
		UiPush()
		
		--Place it in upper right corner
		UiTranslate(UiWidth()+200 - 400*visible, 50)
		-- UiAlign("center middle")
		-- UiTranslate(0, 30)
		-- UiColor(0,0,0,.3)
		-- UiRect(300, 20+90)
		-- UiTranslate(0, -30)
		-- UiColor(1,1,1)
		UiFont("bold.ttf", 24)

		-- local weaponText =  string.format("%s%s\n%s", tag, title, tag)
		for key,gun in pairs(gunGroup)	do 
				-- UiPush()
					UiAlign("center middle")
					UiTranslate(0, 40)
					UiColor(0,0,0,.3)
					UiRect(300, 10+90)
					UiTranslate(0, -30)
					UiColor(1,1,1)
					UiText(gun.name)
					-- if(not IsShapeBroken(gun.id))then	

					-- 	UiText(gun.name)
					-- else
					-- 	UiText(gun.name.." BROKEN")
					-- end
					
					UiTranslate(0, 40)
					
					
					getWeaponAmmoText(gun)--getWeaponAmmoText(gun))
					UiTranslate(0, 30)
				-- UiPop()
		end

			UiPop()

		if(not GetBool("savegame.mod.hideControls")) then
			drawControls()
		end

			-- if GetBool("savegame.mod.mph") then
			-- 	UiImage("mph.png")
			-- 	--Convert to rotation for mph
			-- 	UiRotate(-displayKmh*2/1.609)
			-- else
			-- 	UiImage("kmh.png")
			-- 	--Convert to rotation for kmh
			-- 	UiRotate(-displayKmh)
			-- end
			-- UiImage("needle.png")

		if(not vehicle.sniperMode) then 

			drawDynamicReticle()
		end


	end
end


function drawControls()
		info = {}
		for key,val in ipairs(armedVehicleControlsOrder) do
			local inputKey = armedVehicleControls[val] 
			key = val	
			info[#info+1] = {inputKey,key}
		end
		if(vehicle.sniperMode) then 
			info[#info+1] = {"Scroll","Adjust Zoom"}
		end
		UiPush()
		UiAlign("top left")
		local w = 250
		local h = #info*22 + 30
		UiTranslate(UiWidth()-w-20, UiHeight()-h-20 - 200) -- because I don't know how big the official vehicle UI will be
		UiColor(0,0,0,0.5)
		UiImageBox("ui/common/box-solid-6.png", 250, h, 6, 6)
		UiTranslate(125, 32)
		UiColor(1,1,1)
		UiTranslate(-60, 0)
		for i=1, #info do
			
			local key = info[i][1]
			local func = info[i][2]
			UiFont("bold.ttf", 22)
			UiAlign("right")
			UiText(key)
			UiTranslate(10, 0)
			UiFont("regular.ttf", 22)
			UiAlign("left")
			UiText(func)
			UiTranslate(-10, 22)
		end
		UiPop()
end

function buildWeaponDisplayText(gun)
	
	-- return weaponText	
end

function getWeaponAmmoText(gun)
	if unexpected_condition then error() end
	local currentMagazine = gun.magazines[gun.loadedMagazine].magazinesAmmo[gun.magazines[gun.loadedMagazine].currentMagazine]
	local ammoState = ""

	if(gun.magazines[gun.loadedMagazine].outOfAmmo or IsJointBroken(gun.gunJoint) 
				or (gun.turretJoint and IsJointBroken(gun.turretJoint)))then---or IsShapeBroken(gun.id) ) then
		UiColor(1,0,0)
		ammoState = string.format("%d / %d", 0,0)
	
	elseif(gun.reloading) then
		UiColor(1,1,0)
		ammoState = string.format("%d / %d", 0,0)
	else
		local magazineCapacity	 = currentMagazine.magazineCapacity	
		local ammoCount = currentMagazine.AmmoCount
		ammoState = string.format("%d / %d", ammoCount,magazineCapacity)
	end

	local magazineCount	 = gun.magazines[gun.loadedMagazine].magazineCount - currentMagazine.expendedMagazines
	if(GetBool("savegame.mod.infiniteAmmo")) then
		magazineCount = "9999"
	end


	local weaponText =  string.format("%s  | (%s)", ammoState, magazineCount)
	UiAlign("center right")
	UiText(weaponText)
	UiTranslate(0, 20)
	UiColor(1,1,1)
	UiAlign("center middle")
	UiText(gun.magazines[gun.loadedMagazine].CfgAmmo.name)

end


function drawWeaponReticles(gun)
	-- local cannonLoc = GetShapeWorldTransform(gun.id)
	-- local fwdPos = TransformToParentPoint(cannonLoc.pos, Vec(0,  -10,0))
 --    -- local direction = VecSub(fwdPos, cannonLoc.pos)
 UiPush()
	UiAlign("center middle")
	UiTranslate(UiCenter(), UiMiddle());
	if(gun.canZoom and  vehicle.ZOOMLEVEL>vehicle.ZOOMMIN) then
		if(gun.fireControlComputer) then
			UiImageBox(gun.fireControlComputer,UiWidth()*1.0,UiHeight()*1.0,1,1)
		else
			UiImageBox("MOD/gfx/scopeRegion.png",UiWidth()*1,UiHeight()*1,1,1)
			UiImageBox("MOD/gfx/scopeOutside.png",UiWidth()*1,UiHeight()*1,1,1)
		end
		-- local cannonLoc = GetShapeWorldTransform(gun.id)
		-- local fwdPos = TransformToParentPoint(cannonLoc,Vec(1,0,1) )
		-- -- local cannonLoc = VecSub(cannonLoc.pos,GetCameraTransform().pos)
  --   local direction = VecSub(fwdPos, cannonLoc.pos)

  --   direction = VecAdd(cannonLoc.pos,dir)
  --   -- direction = VecNormalize(direction)
		-- local x, y, dist = UiWorldToPixel(fwdPos)
		-- UiTranslate(x,y)
		

		UiTranslate(0,-((originalFov/100)*5)+
											(originalFov-
												(vehicle.sniperFOV *(1 - (vehicle.ZOOMVAL * vehicle.ZOOMLEVEL))))
												*(originalFov/100))
		if(gun.zoomSight)then 
			UiImage(gun.zoomSight,UiWidth()*1,UiHeight()*1,1,1)
		else
			UiImage("MOD/gfx/t72ScopeInner.png",UiWidth()*1,UiHeight()*1,1,1)
		end
	else
		UiTranslate((originalFov/100)*(gun.sight[1].x*5),((originalFov/100)*30))
		if(gun.weaponType=="MGun") then
			UiImage("MOD/gfx/simpleCrosshair2.png")		
		elseif(gun.weaponType=="rocket") then
			UiImage("MOD/gfx/crosshair-launcher.png")
		else
			UiImage("MOD/gfx/tankCrossHairSimple.png")
			
		end
	end
	UiPop()
	-- local cannonLoc = GetShapeWorldTransform(gun.id)
	-- local fwdPos = TransformToParentPoint(cannonLoc.pos, Vec(0,  -10,0))
 --    -- local direction = VecSub(fwdPos, cannonLoc.pos)
 --    -- direction = VecNormalize(direction)
	-- local x, y, dist = UiWorldToPixel(fwdPos)
	-- -- DebugWatch("x: "..UiWidth()-x.." | y: "..UiHeight()- y)
	-- if dist > 0 then
	-- 	UiTranslate(UiWidth()-x,UiHeight()- y)
	-- 	UiImage("MOD/gfx/shellRear2.png")
	-- end

end







-- cheej
function initCamera()
    cameraX = 0
	cameraY = 0
	zoom = 20
end
function manageCamera()
    local mx, my = InputValue("mousedx"), InputValue("mousedy")
	cameraX = cameraX - mx / 10
	cameraY = cameraY - my / 10
	cameraY = clamp(cameraY, -30, 60)
	local cameraRot = QuatEuler(cameraY, cameraX, 0)
	local cameraT = Transform(VecAdd(Vec(0,0,0), GetVehicleTransform(GetPlayerVehicle()).pos), cameraRot)
	zoom = zoom - InputValue("mousewheel")
	zoom = clamp(zoom, 2, 30)
	local cameraPos = TransformToParentPoint(cameraT, Vec(0, 5, zoom))
	local camera = Transform(VecLerp(cameraPos, GetCameraTransform().pos, 0.5), cameraRot)
	SetCameraTransform(camera)
end

function setReticleScreenPos(projectileHitPos)
	reticleScreenPosX, reticleScreenPosY = UiWorldToPixel(projectileHitPos)
	reticleScreenPos = {reticleScreenPosX, reticleScreenPosY}
end
function removeReticleScreenPos()
	reticleScreenPos = nil	
end

function getOuterReticleWorldPos()

	local crosshairDir = UiPixelToWorld(UiCenter(), UiMiddle()-50)
	local crosshairQuat = QuatDir(crosshairDir)
    local crosshairTr = Transform(GetCameraTransform().pos, crosshairQuat)
    local crosshairHit, crosshairHitPos = RaycastFromTransform(crosshairTr, nil, nil, {vehicle.body})
    if crosshairHit then
        -- DrawDot(crosshairHitPos, 1,1, 1,0,0, 1)
		reticleWorldPos = crosshairHitPos
	else
		reticleWorldPos = nil
    end

end
function drawDynamicReticle()
	if reticleScreenPos ~= nil then
		UiPush()
			UiTranslate(reticleScreenPos[1], reticleScreenPos[2])
			UiAlign('center middle')
			UiColor(1,1,1,0.5)
			UiImageBox('ui/hud/dot-small.png', 15,15, 1,1)
		UiPop()
	end
	UiPush()
		UiTranslate(UiCenter(), UiMiddle()-50)
		UiAlign('center middle')
		UiColor(1,1,1,0.5)
		UiImageBox('ui/hud/target.png', 30,30, 1,1)
	UiPop()

	getOuterReticleWorldPos()
end


function QuatDir(dir) return QuatLookAt(Vec(0, 0, 0), dir) end -- Quat to 3d worldspace dir.
function GetQuatEulerVec(quat) local x,y,z = GetQuatEuler(quat) return Vec(x,y,z) end
---@param tr table
---@param distance number
---@param rad number
---@param rejectBodies table
---@param rejectShapes table
function RaycastFromTransform(tr, distance, rad, rejectBodies, rejectShapes)

	if distance ~= nil then distance = -distance else distance = -300 end

	if rejectBodies ~= nil then for i = 1, #rejectBodies do QueryRejectBody(rejectBodies[i]) end end
	if rejectShapes ~= nil then for i = 1, #rejectShapes do QueryRejectShape(rejectShapes[i]) end end

	local plyTransform = tr
	local fwdPos = TransformToParentPoint(plyTransform, Vec(0, 0, distance))
	local direction = VecSub(fwdPos, plyTransform.pos)
	local dist = VecLength(direction)
	direction = VecNormalize(direction)
	QueryRejectBody(rejectBody)
	local h, d, n, s = QueryRaycast(tr.pos, direction, dist, rad)
	if h then
		local p = TransformToParentPoint(plyTransform, Vec(0, 0, d * -1))
		local b = GetShapeBody(s)
		return h, p, s, b, d
	else
		return nil
	end
end
function DrawDot(pos, l, w, r, g, b, a, dt)
	local dot = LoadSprite("ui/hud/dot-small.png")
	local spriteRot = QuatLookAt(pos, GetCameraTransform().pos)
	local spriteTr = Transform(pos, spriteRot)
	DrawSprite(dot, spriteTr, l or 0.2, w or 0.2, r or 1, g or 1, b or 1, a or 1, dt or true)
end
function AabbGetShapeCenterPos(shape)
	local mi, ma = GetShapeBounds(shape)
	return VecLerp(mi,ma,0.5)
end