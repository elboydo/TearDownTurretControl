


--[[
**********************************************************************
*
* FILEHEADER: Elboydo's vehicle mounted gun and turret control script 
*
* FILENAME :        mountedGun.lua             
*
* DESCRIPTION :
*       File that controls player vehicle turrets within the game teardown (2020)
*
*		File Handles both player physics controlled and in vehicle controlled turrets
*		
*		
*
* SETUP FUNCTIONS :
*		In accessor init: 
*
*       setValues(vehicle,weaponFeatures) - Establishes environment variables for vehicle
*       gunInit() 						  - Establishes vehicle gun state
*
*		In accessor Tick(dt):
*
*		gunTick(dt)						  - Manages gun control during gameplay
*
* NOTES :
*       Future versions may ammend issue with exact gun location
*		physics based gun control lost after driving player vehicle.
*       
* 		Please ensure to add player click to hud.lua. 
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
*		provided to teardown modders at the inception of this mod.  
*
* HUB REPO: https://github.com/elboydo/TearDownTurretControl
*
* CHANGES :
*
*			Release: Public release V_1 - NOV 11 - 11 - 2020
*



]]

vehicle = {
	-- mainName 				= "technicalVehicle",
	-- Vehiclename 			= "technicalBody",
 --  	CannonName 				= "canon",
 --  	CannonJointName 		= "gunMount",
 --  	Create 					= "elboydo",
 --  	barrelOffset 			= .6
}

--[[
 multi purpose gun config
]]

weaponFeatures = {
	-- armed 					= true,
	-- timeToFire 				= 1,
	-- magazineCapacity 		= 10,
	-- reloadTime 				= 1,
	-- hasRockets 				= true,
	-- hasRocketCapacity		= false,
	-- rocketCapacity 			= 50,
	-- rocketStartingAmmo 		= 25,
	-- startRockets			= false,  
	-- hasMG 					= true,
	-- hasMGCapacity			= false,
	-- MGCapacity 				= 500,
	-- MGStartingAmmo 			= 250,
	-- displayWeaponDetails	= false,
	-- rocketExtraconsumption 	= 5,
	-- rocketReloadPenalty 	= 1 
}


--[[
 MG only config
]]

-- weaponFeatures = {
-- 	armed 					= true,
-- 	timeToFire 				= 1,
-- 	magazineCapacity 		= 10,
-- 	reloadTime 				= 1,
-- 	hasRockets 				= false,
-- 	hasRocketCapacity		= false,
-- 	rocketCapacity 			= 50,
-- 	rocketStartingAmmo 		= 25,
-- 	startRockets			= false,  
-- 	hasMG 					= true,
-- 	hasMGCapacity			= false,
-- 	MGCapacity 				= 500,
-- 	MGStartingAmmo 			= 250,
-- 	displayWeaponDetails	= false,
-- 	rocketExtraconsumption 	= 5,
-- 	rocketReloadPenalty 	= 1 
-- }

--[[
 rocket Launcher config
]]

-- weaponFeatures = {
-- 	armed 					= true,
-- 	timeToFire 				= 1,
-- 	magazineCapacity 		= 5,
-- 	reloadTime 				= 1,
-- 	hasRockets 				= true,
-- 	hasRocketCapacity		= false,
-- 	rocketCapacity 			= 50,
-- 	rocketStartingAmmo 		= 25,
-- 	startRockets			= true,  
-- 	hasMG 					= false,
-- 	hasMGCapacity			= false,
-- 	MGCapacity 				= 500,
-- 	MGStartingAmmo 			= 250,
-- 	displayWeaponDetails	= false,
-- 	rocketExtraconsumption 	= 5,
-- 	rocketReloadPenalty 	= 1 
-- }

function setValues(t_vehicle,t_weapon)
	vehicle = t_vehicle
	weaponFeatures = t_weapon
end

function gunInit()
	vehicle.body = FindBody(vehicle.Vehiclename,true)
	vehicle.transform = GetBodyTransform(vehicle.body)
	vehicle.gun  = FindShape(vehicle.CannonName,true)
	
	vehicle.CannonJoint = FindJoint(vehicle.CannonJointName,true)	
	vehicle.reloadRockets = FindShape(weaponFeatures.ammoBoxRocketName,true)
	vehicle.reloadMG = FindShape(weaponFeatures.ammoBoxMGName,true)

	vehicleArmed = weaponFeatures.armed
-- lazy flavour text
	gunStateText = "Fire"
-- relaod management
	reloading = false
	outOfAmmo = false
	reloadTime = weaponFeatures.reloadTime
	currentReload = 0
-- Gun firemode
	-- time to fire
	maxDist = 500

	firing = false
	timeToFire = weaponFeatures.timeToFire	
	fireTime = timeToFire
	magazineCapacity = weaponFeatures.magazineCapacity
	shotsLeft = magazineCapacity
	fireRate = timeToFire/shotsLeft

-- init weapon Features
	armed = weaponFeatures.armed
	hasRockets = weaponFeatures.hasRockets
	hasRocketCapacity = weaponFeatures.hasRocketCapacity
	rocketCapacity = weaponFeatures.rocketCapacity
	rocketAmmoLeft = weaponFeatures.rocketStartingAmmo
	hasMG = weaponFeatures.hasMG
	hasMGCapacity = weaponFeatures.hasMGCapacity
	MGCapacity = weaponFeatures.MGCapacity
	MGAmmoLeft = weaponFeatures.MGStartingAmmo
	rocketMode = weaponFeatures.startRockets
	displayWeaponDetails = weaponFeatures.displayWeaponDetails

-- sound effects
	shootSound = LoadSound("chopper-shoot")
	rocketSound = LoadSound("tools/launcher0.ogg")
-- smoke effects
	smokeTimer = 0	
	gunSmokedissipation = 3
	gunSmokeSize =1
	gunSmokeGravity = 2
	carDriven = false

	initTags()


end

function initTags()
	if hasRockets then
		updateRocketAmmoVals()
	else 
		RemoveTag(vehicle.reloadRockets, "interact")
	end
	if hasMG then 
		updateMGAmmoVals()
	else
		RemoveTag(vehicle.reloadMG, "interact")
	end
	if armed then
		updateGunAmmoVals()
	else
		RemoveTag(vehicle.gun,"interact")
	end
end


function gunTick(dt)
	if(armed) then
		checkAmmo(dt)
		checkAmmoSupply()
		handleGunOperation(dt)
	end
end

function checkAmmo(dt)
	if(hasRockets and hasMG) then
		if (IsShapeOperated(vehicle.reloadRockets)and not rocketMode) then
			rocketMode = true
			reload()
		elseif (IsShapeOperated(vehicle.reloadMG)and rocketMode)then
			rocketMode = false	
			reload()
		end 
	end
end
function checkAmmoSupply()
	if rocketMode then
		if (rocketHasAmmo()) then
			outOfAmmo = false
		else
			outOfAmmo = true
		end
	else
			if mgHasAmmo() then
				outOfAmmo = false
			else
				outOfAmmo = true
			end
	end
end

function  setMGAmmo(ammoVal)
	if ammoVal >= MGCapacity then
		MGAmmoLeft = MGCapacity
	elseif ammoVal <= 0 then
		MGAmmoLeft = 0
	else
		MGAmmoLeft  =ammoVal
	end
	
end
function setRocketAmmo( ammoVal)
	if ammoVal >= rocketCapacity then
		rocketAmmoLeft = rocketCapacity
	elseif ammoVal <= 0 then
		rocketAmmoLeft = 0
	else
		rocketAmmoLeft  =ammoVal
	end
end

function updateRocketAmmoVals()
	if(hasRockets) then
		if (hasRocketCapacity) then
			if(rocketAmmoLeft > 0)	then
				SetTag(vehicle.reloadRockets,"interact","Load Rockets: "..rocketAmmoLeft.."/"..rocketCapacity)
			else
				SetTag(vehicle.reloadRockets,"interact","Out of Ammo: "..rocketAmmoLeft.."/"..rocketCapacity)
			end
		else
			SetTag(vehicle.reloadRockets,"interact","Load Rockets")	
		end
	end
end
function rocketHasAmmo()
	if hasRockets and ((hasRocketCapacity and rocketAmmoLeft>0)or (not hasRocketCapacity)) then
		return true
	else 
		return false
	end
end

function mgHasAmmo()
		if hasMG and ((hasMGCapacity and MGAmmoLeft>0)or (not hasMGCapacity)) then
			return true

		else 
			return false	
		end 
end
function updateMGAmmoVals()
	if (hasMG) then
		if (hasMGCapacity) then
			if(MGAmmoLeft >0) then
				SetTag(vehicle.reloadMG,"interact","Load MG rounds: "..MGAmmoLeft.."/"..MGCapacity)
			else
				SetTag(vehicle.reloadMG,"interact","Out of Ammo: "..MGAmmoLeft.."/"..MGCapacity)
			end
		else
			SetTag(vehicle.reloadMG,"interact","Load MG rounds")
		end
	end
end

function updateGunAmmoVals()
	if rocketMode then
		if(hasRocketCapacity and displayWeaponDetails)then 
			SetTag(vehicle.gun,"interact",gunStateText.." Rocket! "..rocketAmmoLeft.."/"..rocketCapacity)
		elseif(hasRocketCapacity and rocketAmmoLeft <=0)then
				SetTag(vehicle.gun,"interact","Rocket Out of Ammo")
				outOfAmmo = true
		else
			SetTag(vehicle.gun,"interact",gunStateText.." Rocket!")
			
		end
	else
		if(hasMGCapacity and displayWeaponDetails) then
			SetTag(vehicle.gun,"interact",gunStateText.." MG! "..MGAmmoLeft.."/"..MGCapacity)
		elseif(hasMGCapacity and MGAmmoLeft <=0) then
			SetTag(vehicle.gun,"interact","MG Out of Ammo")
			outOfAmmo = true
		else
			SetTag(vehicle.gun,"interact",gunStateText.." MG!")
		end
	end

end

function inVehicleGunControl(dt)
	if ((not firing or not reloading)and not outOfAmmo) then
		firing = true
		gunStateText="Firing"
		smokeTimer = timeToFire
		--SetTag(vehicle.gun,"interact","Firing")
	end
	if(firing) then
		fireTime = fireTime - dt
		fireControl(dt)
	elseif (reloading) then
		handleReload(dt)
	end
end

function handleGunOperation(dt)
	if(											(GetBool("game.player.usevehicle")
												and HasTag(GetVehicleBody(GetPlayerVehicle()),vehicle.Vehiclename) ))then
		turretRotatation()
		if(not carDriven ) then
			carDriven = true
		end
	elseif (carDriven) then
		SetJointMotor(vehicle.CannonJoint, 0)

	end
	if ((not firing and not reloading) and (
											(IsShapeOperated(vehicle.gun)) 
											or 
											(GetBool("game.player.usevehicle") 
												and GetBool("mouse.pressed") 
												and HasTag(GetVehicleBody(GetPlayerVehicle()),vehicle.Vehiclename) )))
	then
		firing = true
		smokeTimer = timeToFire
		gunStateText = "Firing"
		--SetTag(vehicle.gun,"interact","Firing")
	end

	if(firing) then
		fireTime = fireTime - dt
		fireControl(dt)
	elseif (reloading) then
		handleReload(dt)
	end

end

function fireControl(dt)
	if(fireTime < (fireRate*shotsLeft)) then
		if rocketMode then
			if(not hasRocketCapacity or rocketAmmoLeft>0)then

				fire(rocketSound,.2,1)
				smoke(dt,2)
				shotsLeft 	=	shotsLeft- weaponFeatures.rocketExtraconsumption
				reloadTime 	= 	reloadTime	+ weaponFeatures.rocketReloadPenalty
				if(hasRocketCapacity)then
					setRocketAmmo(rocketAmmoLeft-1)
					updateRocketAmmoVals()
				end
			else
				printStr("Out of Ammo")
				
				
			end
		else 
			if(not hasMGCapacity or MGAmmoLeft >0) then
				fire(shootSound,0,2)
				smoke(dt,1)
				if(hasMGCapacity) then
					setMGAmmo(MGAmmoLeft-1)
					updateMGAmmoVals()
					
				end
			else
				printStr("Out of Ammo")
			end						
		end
		updateGunAmmoVals()
		if(not outOfAmmo) then
			shotsLeft = shotsLeft -1
			if(shotsLeft <= 0)	then
				reload()
			end
		else
			printStr("Out of Ammo")
		end
	end
end

function reload()
	shotsLeft = magazineCapacity
	fireTime = timeToFire
	firing = false
	reloading = true 
	--SetTag(vehicle.gun,"interact","Reloading")
	gunStateText = "Reloading"
	updateGunAmmoVals()

end

function handleReload( dt )
	if  currentReload < reloadTime then
		currentReload = currentReload + dt
	else
		currentReload = 0
		reloading = false
		gunStateText = "Fire"
		updateGunAmmoVals()
		-- SetTag(vehicle.gun,"interact","Fire")
	end
end

function smoke(dt,smokeFactor)
	if smokeTimer > 0 then
		local cannonLoc = GetShapeWorldTransform(vehicle.gun)
		local fwdPos = TransformToParentPoint(plyTransform, Vec(0, 0, 100))
		local direction = VecSub(fwdPos, cannonLoc.pos)
		direction = VecNormalize(direction) -- direction the player is looking
		-- local cannonLocTransform = TransformToParentPoint(cannonLoc, Vec(0, 0, 1))
		smokePos = cannonLoc.pos
		smokePos[2] =smokePos[2] +  vehicle.barrelOffset
		local smokeX = clamp(((direction[1]*360)+math.random(1,10)*0.1),-gunSmokedissipation,gunSmokedissipation)
		local smokeY = clamp((direction[3]*10)+math.random(1,10),-gunSmokedissipation,gunSmokedissipation)
		SpawnParticle("smoke", smokePos, Vec(-smokeX, 1.0+math.random(1,10)*0.1,smokeY ), (gunSmokeSize*smokeFactor), gunSmokeGravity*smokeFactor)
		smokeTimer = smokeTimer - dt
	end
end

function fire(sound,fireVec,shotType)
	local cannonLoc = GetShapeWorldTransform(vehicle.gun)
	
	cannonLoc.pos[2] = cannonLoc.pos[2]+  (vehicle.barrelOffset)

	RaycastRejectBody(vehicle.body)
	RaycastRejectBody(vehicle.gun)
	local fwdPos = TransformToParentPoint(cannonLoc, Vec(0, 0, maxDist * -1))
    local direction = VecSub(fwdPos, cannonLoc.pos)
     -- printloc(direction)
    direction = VecNormalize(direction)

    hit, dist = Raycast(cannonLoc.pos, direction, maxDist)
    PlaySound(sound, cannonLoc.pos, 5, false)
    if hit then
		hitPos = TransformToParentPoint(cannonLoc, Vec(0, dist * -1,(dist*.1)*fireVec))
	else
		hitPos = TransformToParentPoint(cannonLoc, Vec(0,  maxDist * -1,(dist*.1)*fireVec))
	end
      	p = cannonLoc.pos

		d = VecNormalize(VecSub(hitPos, p))
		spread = 0.03
		d[1] = d[1] + ((math.random()-0.5)*2*spread)*dist/maxDist
		d[2] = d[2] + ((math.random()-0.5)*2*spread)*dist/maxDist
		d[3] = d[3] + ((math.random()-0.5)*2*spread)*dist/maxDist
		d = VecNormalize(d)
		p = VecAdd(p, VecScale(d, 0.5))
		Shoot(p, d,shotType)	
end


function turretRotatation()
	SetString("fun")
	local forward = turretAngle(0,1,0)
	local back 	  = turretAngle(0,-1,0) 
	local left 	  = turretAngle(-1,0,0)
	local right   = turretAngle(1,0,0)

	local bias = 0.1
	if(forward<.98) then
		if(left>right+bias) then
			SetJointMotor(vehicle.CannonJoint, 1*left)
		elseif(right>left+bias) then
			SetJointMotor(vehicle.CannonJoint, -1*right)
		else
			SetJointMotor(vehicle.CannonJoint, 0)
		end
	else
		SetJointMotor(vehicle.CannonJoint, 0)
	end 
	-- SetString("hud.notification",
	-- 	"forward: "..
	-- 	forward..
	-- 	"\nback: "..
	-- 	back..
	-- 	"\nleft: "..
	-- 	left..
	-- 	"\nright: "..
	-- 	right)
end

function turretAngle(x,y,z)
	local gunTransform = GetShapeWorldTransform(vehicle.gun)
	local fwdPos = TransformToParentPoint(GetCameraTransform(), Vec(0, 0, 100))
	local toPlayer = VecNormalize(VecSub(fwdPos, gunTransform.pos))
	local forward = TransformToParentVec(gunTransform, Vec(x,  y, Z))
	local orientationFactor = clamp(VecDot(forward, toPlayer) * 0.7 + 0.3, 0.0, 1.0)
	return orientationFactor
end

function orientationCalc()

	local gunTransform = GetShapeWorldTransform(vehicle.gun)
	local temp = gunTransform[2]
	-- gunTransform.pos[2] = gunTransform[3]
	-- gunTransform.pos[3] = temp
	local fwdPos = TransformToParentPoint(GetCameraTransform(), Vec(0, 0, 100))
	local vehicleFwdPos = TransformToParentPoint(vehicle.transform, Vec(0, 0, 100))


	-- local toPlayer = VecNormalize(VecSub(GetPlayerPos(), chopperTransform.pos))
	-- local forward = TransformToParentVec(chopperTransform, Vec(0, 0, -1))
	-- local orientationFactor = clamp(VecDot(forward, toPlayer) * 0.7 + 0.3, 0.0, 1.0)
		-- hitPos = TransformToParentPoint(cannonLoc, Vec(0,  maxDist * -1,fireVec)

	local toPlayer = VecNormalize(VecSub(fwdPos, gunTransform.pos))
	local forward = TransformToParentVec(gunTransform, Vec(0,  1, 0))
	local orientationFactor = clamp(VecDot(forward, toPlayer) * 0.7 + 0.3, 0.0, 1.0)
	return orientationFactor
	-- body
end

function orientationCalc2()

	local gunTransform = GetShapeWorldTransform(vehicle.gun)
	local temp = gunTransform[2]
	-- gunTransform.pos[2] = gunTransform[3]
	-- gunTransform.pos[3] = temp
	local fwdPos = TransformToParentPoint(GetCameraTransform(), Vec(0, 0, 100))
	local vehicleFwdPos = TransformToParentPoint(vehicle.transform, Vec(0, 0, 100))


	-- local toPlayer = VecNormalize(VecSub(GetPlayerPos(), chopperTransform.pos))
	-- local forward = TransformToParentVec(chopperTransform, Vec(0, 0, -1))
	-- local orientationFactor = clamp(VecDot(forward, toPlayer) * 0.7 + 0.3, 0.0, 1.0)
		-- hitPos = TransformToParentPoint(cannonLoc, Vec(0,  maxDist * -1,fireVec)

	local toPlayer = VecNormalize(VecSub(fwdPos, gunTransform.pos))
	local forward = TransformToParentVec(gunTransform, Vec(-1,  0, 0))
	local orientationFactor = clamp(VecDot(forward, toPlayer) * 0.7 + 0.3, 0.0, 1.0)
	return orientationFactor
	-- body
end

function orientationCalc3()

	local gunTransform = GetShapeWorldTransform(vehicle.gun)
	local temp = gunTransform[2]
	-- gunTransform.pos[2] = gunTransform[3]
	-- gunTransform.pos[3] = temp
	local fwdPos = TransformToParentPoint(GetCameraTransform(), Vec(0, 0, 100))
	local vehicleFwdPos = TransformToParentPoint(vehicle.transform, Vec(0, 0, 100))


	-- local toPlayer = VecNormalize(VecSub(GetPlayerPos(), chopperTransform.pos))
	-- local forward = TransformToParentVec(chopperTransform, Vec(0, 0, -1))
	-- local orientationFactor = clamp(VecDot(forward, toPlayer) * 0.7 + 0.3, 0.0, 1.0)
		-- hitPos = TransformToParentPoint(cannonLoc, Vec(0,  maxDist * -1,fireVec)

	local toPlayer = VecNormalize(VecSub(fwdPos, gunTransform.pos))
	local forward = TransformToParentVec(gunTransform, Vec(1,  0, 0))
	local orientationFactor = clamp(VecDot(forward, toPlayer) * 0.7 + 0.3, 0.0, 1.0)
	return orientationFactor
	-- body
end


function getJointCondition()
	if( IsJointBroken(vehicle.CannonJoint) ) then
		SetString("hud.notification","joint broken")
	else
		SetString("hud.notification","joint okay")
	end
end


function UiIsMousePressed()
	return  GetBool("mouse.pressed")
end

function quickFixCoords( pos )
	-- body
end

function clamp(val, lower, upper)
    if lower > upper then lower, upper = upper, lower end -- swap if boundaries supplied the wrong way
    return math.max(lower, math.min(upper, val))
end

function printloc(x)

	SetString("hud.notification",
	"X "..
	(x[1]*360)..
	" Y"..
	x[2]..
	" Z"..
	x[3]
	) -- this prints the coordinates top center of the screen  

end


function printRot(x)

	SetString("hud.notification",
	"X "..
	x[2]..
	"\nY"..
	x[3]..
	"\nZ"..
	x[4]
	) -- this prints the rotation top center of the screen  

end

function printStr(x)
	SetString("hud.notification",x)
end