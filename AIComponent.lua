#include "common.lua"


--[[
**********************************************************************
*
* FILEHEADER: Elboydo's Armed Vehicles Framework (AVF) 
*
* FILENAME :        AiComponent.lua             
*
* DESCRIPTION :
*       File that manages AI operations and teams 
*
*		Controls here manage AI aiming, weapon systems and other behaviors
*		
*
]]

AVF_ai = {
	OPFOR = 0,
	BLUFOR = 1,
	INDEP = 2,

	vehicles = {

	},

	bluForAI = {


	},
	opForAI = {


	},
	indepAI = {


	},
	templateVehicle = {
		id = nil,
		info = nil, 
		features = nil, 
		side = nil,
		range = 100,
		precision = 1,
		persistance = 1,
	}
}




function AVF_ai:initAi()

	index = #self.vehicles+1
 	self.vehicles[index] = deepcopy(self.templateVehicle)
 	self.vehicles[index].id = vehicle.id
 	self.vehicles[index].info = vehicle
 	self.vehicles[index].features = vehicleFeatures
 	local side = tonumber(GetTagValue(vehicle.id,"avf_ai"))
 	self.vehicles[index].side = side
 	if(side) then 
	 	if(side == self.OPFOR) then
	 		self.opForAI[#self.opForAI+1] = index
	 	elseif(side == self.BLUFOR) then  
	 		self.bluForAI[#self.bluForAI+1] = index
	 	elseif(side == self.INDEP) then 
	 		self.indepAI[#self.indepAI+1] = index
	 	end
	 end

 end


 --- function that operates through ai behaviors
 function AVF_ai:aiTick(dt)
 	
 	-- DebugWatch("avf ai vehicles",#self.vehicles)
 	for key,ai in ipairs(self.vehicles) do
 		-- self:targetSelection(ai)
 		vehicle = ai.info
 		vehicleFeatures = ai.features
 		self:weaponAiming(ai)
 	end
 end


function AVF_ai:targetSelection(ai)
	local closestTarget = nil
	local closestDistance = 1000000
	if(ai.side~=self.OPFOR) then 
		for _,val in ipairs(self.opForAI) do 
			self:canSee(targetPos)

		end
	end 
	DebugWatch("side: ",ai.side)
	return closestTarget
end


function AVF_ai:canSee(targetPos)
	local commanderPos = GetVehicleTransform(vehicle.id)
	commanderPos.pos = TransformToParentPoint(commanderPos,Vec(0,2,0))

	local fwdPos = VecSub(commanderPos.pos,targetPos.pos)
	local dir = VecNormalize(fwdPos)
	if(IsHandleValid(GetPlayerVehicle())) then 
		QueryRejectVehicle(GetPlayerVehicle())
	end
	
	local hit, dist,normal, shape = QueryRaycast(targetPos.pos, dir , 100,0,true)



	local hitVehicle = false
	for _,shape2 in ipairs(vehicle.shapes) do 
		if(shape == shape2) then
			hitVehicle =true
		end

	end
	return hitVehicle,dist
end

function AVF_ai:weaponAiming(ai)

	local targetPos = GetPlayerCameraTransform()
	targetPos.pos = TransformToParentPoint(targetPos,Vec(0,-0.5,0))
	targetPos.pos = VecAdd(targetPos.pos,VecScale(GetPlayerVelocity(),GetTimeStep()*2))
	local commanderPos = GetVehicleTransform(vehicle.id)
	commanderPos.pos = TransformToParentPoint(commanderPos,Vec(0,2,0))

	local fwdPos = VecSub(commanderPos.pos,targetPos.pos)
	local dir = VecNormalize(fwdPos)
	if(IsHandleValid(GetPlayerVehicle())) then 
		QueryRejectVehicle(GetPlayerVehicle())
	end
	
	local hit, dist,normal, shape = QueryRaycast(targetPos.pos, dir , 100,0,true)
	-- DebugLine(targetPos.pos,commanderPos.pos)
	-- DebugWatch("hit",shape)


	local hitVehicle = false
	for _,shape2 in ipairs(vehicle.shapes) do 
		if(shape == shape2) then
			hitVehicle =true
		end

	end
		-- DebugWatch("hit vehicle",hitVehicle)
	if(hit and hitVehicle) then 
		for key,turretGroup in pairs(vehicleFeatures.turrets) do
			for key2,turret in ipairs(turretGroup) do
				self:turretRotatation(ai,turret,turret.turretJoint,targetPos)
				
			end
		end
		self:gunAiming(ai,targetPos)
	end
	return hitVehicle
end

function AVF_ai:gunAiming(ai,targetPos)
	for key,gunGroup in pairs(vehicleFeatures.weapons) do
		
		-- utils.printStr(#gunGroup)
			for key2,gun in ipairs(gunGroup) do

				local previouslyAimed = gun.aimed
				self:gunLaying(ai,gun,targetPos)	
				if(not gun.reloading and gun.persistance) then 
					-- DebugWatch("gun firing",gun.persistance)
					if(not gun.aimed and (previouslyAimed or (gun.persistance and gun.persistance>0))) then 
						gun.persistance = gun.persistance - GetTimeStep()
					end
					
				 	if(gun.persistance>0) then 
				 		self:gunFiring(gun)
				 	elseif(gun.firing) then
				 		self:gunFiring(gun)
				 		gun.firing = false
				 	end
				end
			end
	end			

end


---- must handle multiple guns
---- if gun angle up > 0 then gun goes down and vice versa, with bias to control
function AVF_ai:gunLaying(ai,gun,targetPos)
	local up = self:gunAngle(0,0,-1,gun,targetPos)
	local down = self:gunAngle(0,0,1	,gun,targetPos)
	local left = self:gunAngle(1,0,0,gun,targetPos)
	local right = self:gunAngle(-1,0,0	,gun,targetPos)
	local forward = self:gunAngle(0,-1,0	,gun,targetPos)
	local bias = 0.1
	gun.aimed = false

	-- DebugWatch("gun up: ",
	-- 		up)
	-- DebugWatch("gun down: ",
	-- 		down)
	-- DebugWatch("gun left: ",
	-- 		left)
	-- DebugWatch("gun right: ",
	-- 		right)
	-- DebugWatch("gun forward: ",
	-- 		forward)
	local dir = 0
	if(up < down-bias*0.1)then  -- and up-bias*.5>0) then 
		dir = -1
	elseif(up > down+bias*0.2 )then  --and down-bias*.5>0) then
		dir = 1
	end
	if(left >right-bias and left<right+bias and forward-bias <0) then 

		gun.persistance = ai.persistance
		gun.aimed = true
		gun.firing = true
		

	end 

	-- bias = bias * math.random(-1,1)/5
	SetJointMotor(gun.gunJoint, dir*bias)
	
end

function AVF_ai:gunFiring(gun)
	dt = GetTimeStep()
	
	local firing = false
	if(gun.persistance<=0)then
		
		if( not gun.reloading and gun.tailOffSound and gun.rapidFire)then
			local cannonLoc = GetShapeWorldTransform(gun.id)
			PlaySound(gun.tailOffSound, cannonLoc.pos, 5)
			gun.rapidFire = false
		end
	else 
		firing = true
	end

	
	if( not gun.reloading and not (IsJointBroken(gun.gunJoint)or (gun.turretJoint and IsJointBroken(gun.turretJoint))  ))then	---not IsShapeBroken(gun.id) and
		if(not gun.magazines[gun.loadedMagazine].outOfAmmo and gun.magazines[gun.loadedMagazine].magazinesAmmo[gun.magazines[gun.loadedMagazine].currentMagazine]) then
			local currentMagazine = gun.magazines[gun.loadedMagazine].magazinesAmmo[gun.magazines[gun.loadedMagazine].currentMagazine]
			if(currentMagazine.AmmoCount > 0) then  
			    if( gun.loopSoundFile)then
			    	if not gun.rapidFire then
			    		
			    		gun.rapidFire = true

			    	end
					local cannonLoc = GetShapeWorldTransform(gun.id)

					PlayLoop(gun.loopSoundFile, cannonLoc.pos, 5)
					
				end
				
				if (gun.timeToFire <=0) then
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
							reloadGun(gun)
							
							
						end
						
					end
				elseif (gun.timeToFire) then
					gun.timeToFire = gun.timeToFire - dt
				end

			end

		end
	end

end



function AVF_ai:turretRotatation(ai,turret,turretJoint,targetPos)

	if(turret)then 

		local turret = turret.id
		local forward = self:turretAngle(0,1,0,turret,targetPos)
		local back 	  = self:turretAngle(0,-1,0,turret,targetPos) 
		local left 	  = self:turretAngle(-1,0,0,turret,targetPos)
		local right   = self:turretAngle(1,0,0,turret,targetPos)
		local up 	  = self:turretAngle(0,0,1,turret,targetPos)
		local down 	  = self:turretAngle(0,0,-1,turret,targetPos)

		-- DebugWatch("angles",
		-- 	"forward: "..
		-- 	forward..
		-- 	"\nback: "..
		-- 	back..
		-- 	"\nleft: "..
		-- 	left..
		-- 	"\nright: "..
		-- 	right..
		-- 	"\nup: "..
		-- 	up..
		-- 	"\ndown: "..
		-- 	down)		
		local bias = 0.05 * ai.precision
		bias = bias * math.random(-1,1)
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

function AVF_ai:turretAngle(x,y,z,turret,targetPos)


	 	-- DebugWatch("avf ai turret test ",1)
	local turretTransform = GetShapeWorldTransform(turret)
	turretTransform=GetShapeWorldTransform(vehicleFeatures.commanderPos) 
	local fwdPos = targetPos.pos
	local toPlayer = VecNormalize(VecSub(turretTransform.pos,fwdPos))
	local forward = TransformToParentVec(turretTransform, Vec(x,  y, z))
	local orientationFactor = clamp(VecDot(forward, toPlayer) * 0.7 + 0.3, 0.0, 1.0)
	
	return orientationFactor
end


function AVF_ai:gunAngle(x,y,z,gun,targetPos)

	 	-- DebugWatch("avf ai turret test ",1)
	local gunTransform = GetShapeWorldTransform(gun.id)
	 
	local fwdPos = targetPos.pos
	
	---fwdPos = {fwdPos[1],fwdPos[3],fwdPos[2]}
	local toPlayer = VecNormalize(VecSub(gunTransform.pos,fwdPos))
	local forward = TransformToParentVec(gunTransform, Vec(x,  y, z))
	local orientationFactor = clamp(VecDot(forward, toPlayer) * 0.7 + 0.3, 0.0, 1.0)
	-- DebugLine(gunTransform.pos,fwdPos,1,0,0,1)
	local distance = VecLength()
	return orientationFactor
end