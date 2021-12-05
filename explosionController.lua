explosionController = {

	test =  "hello world",

	explosionPos = Vec(),

	trails = {},


	smoke = {
		age = 0,
		size = 0,
		life = 0,
		next = 0,
		vel = 0,
		gravity = 0,
		amount = 0,
	},



	fire = {
		age = 0,
		life = 0,
		size = 0,
	},



	flash = {
		age = 0,
		life = 0,
		intensity = 0,
	},

	light = {
		age = 0,
		life = 0,
		intensity = 0,
	},


	maxMass = 1000,
	forceCoef = 250

}


function explosionController:rnd(mi, ma)
	return math.random(1000)/1000*(ma-mi) + mi
end

function explosionController:rndVec(t)
	return Vec(self:rnd(-t, t), self:rnd(-t, t), self:rnd(-t, t))
end



function explosionController:trailsAdd(pos, vel, life, size, damp, gravity)
	t = {}
	t.pos = VecCopy(pos)
	t.vel = VecAdd(Vec(0, vel*0.7, 0 ), self:rndVec(vel))
	t.size = size
	t.age = 0
	t.damp = damp
	t.gravity = gravity
	t.life = self:rnd(life*0.5, life*1.5)
	t.nextSpawn = 0
	self.trails[#self.trails+1] = t
end

function explosionController:trailsUpdate(dt)
	for i=#self.trails,1,-1 do
		local t = self.trails[i]
		if(t) then 
			t.vel[2] = t.vel[2] + t.gravity*dt
			t.vel = VecScale(t.vel, t.damp)
			t.pos = VecAdd(t.pos, VecScale(t.vel, dt))
			t.age = t.age + dt
			local q = 1.0 - t.age / t.life
			if q > 0.1 then
				local r = t.size * q + 0.05
				local spawnRate = 0.8*r/VecLength(t.vel)
				while t.nextSpawn < t.age do
					local w = 0.8-q*0.5
					local w2 = 0.9
					local v = VecScale(t.vel, 0.25)
					ParticleReset()
					ParticleType("smoke")
					ParticleColor(w, w*0.95, w*0.9, w2, w2*0.95, w2*0.9)
					ParticleRadius(r)
					ParticleAlpha(q, 0)
					ParticleDrag(2.0)
					SpawnParticle(t.pos, v, self:rnd(0.5, 2.0))
					t.nextSpawn = t.nextSpawn + spawnRate
				end
			else
				self.trails[i] = self.trails[#self.trails]
				self.trails[#self.trails] = nil
			end
		end
	end
end


function explosionController:smokeUpdate(pos, dt)
	
	if self.smoke.age < self.smoke.life then
		self.smoke.age = self.smoke.age + dt

		local q = 1.0 - self.smoke.age / self.smoke.life
		for i=1, self.smoke.amount*q do
			local w = 0.8-q*0.6
			local w2 = 1.0
			local r = self.smoke.size*(0.5 + 0.5*q)
			local v = VecAdd(Vec(0, 1*q+q*self.smoke.vel, 0), self:rndVec(1*q))
			local p = VecAdd(pos, self:rndVec(r*0.3))
			ParticleReset()
			ParticleType("smoke")
			ParticleColor(w, w*0.95, w*0.9, w2, w2*0.95, w2*0.9)
			ParticleRadius(0.5*r, r)
			ParticleGravity(self:rnd(0,self.smoke.gravity))
			ParticleDrag(1.0)
			ParticleAlpha(q, q, "constant", 0, 0.5)
			SpawnParticle(p, v, self:rnd(3,5))
		end
	end
end


function explosionController:fireUpdate(pos, dt)

	if self.fire.age < self.fire.life then
		self.fire.age = self.fire.age + dt
		local q = 1.0 - self.fire.age / self.fire.life
		for i=1, 16 do
			local v = self:rndVec(self.fire.size*10*q)
			local p = pos
			local life = self:rnd(0.2, 0.7)
			life = 0.5 + life*life*life * 1.5
			ParticleReset()
			ParticleColor(1, 0.6, 0.4, 1, 0.3, 0.2)
			ParticleAlpha(1, 0)
			ParticleRadius(self.fire.size*q, 0.5*self.fire.size*q)
			ParticleGravity(1, self:rnd(1, 10))
			ParticleDrag(0.6)
			ParticleEmissive(self:rnd(2, 5), 0, "easeout")
			ParticleTile(5)
			SpawnParticle(p, v, life)
		end
	end
end


function explosionController:flashTick(pos, dt)

	if self.flash.age < self.flash.life then
		self.flash.age = self.flash.age + dt
		local q = 1.0 - self.flash.age / self.flash.life
		PointLight(pos, 1, 0.5, 0.2, self.flash.intensity*q) 
	end
end



function explosionController:lightTick(pos, dt)

	if self.light.age < self.light.life then
		self.light.age = self.light.age + dt
		local q = 1.0 - self.light.age / self.light.life
		local l = q * q
		local p = VecAdd(pos, self:rndVec(0.5*l))
		PointLight(p, 1, 0.4, 0.1, self.light.intensity*l)
	end
end

function explosionController:explosionSparks(count, vel)
	for i=1, count do
		local v = VecAdd(Vec(0, vel, 0 ), self:rndVec(self:rnd(vel*0.5, vel*1.5)))
		local life = self:rnd(0, 1)
		life = life*life * 5
		ParticleReset()
		ParticleEmissive(5, 0, "easeout")
		ParticleGravity(-10)
		ParticleRadius(0.03, 0.0, "easein")
		ParticleColor(1, 0.4, 0.3)
		ParticleTile(4)
		SpawnParticle(explosionPos, v, life)
	end
end

function explosionController:explosionDebris(count, vel)
	for i=1, count do
		local r = self:rnd(0, 1)
		life = 0.5 + r*r*r*3
		r = (0.4 + 0.6*r*r*r)
		local v = VecAdd(Vec(0, r*vel*0.5, 0), VecScale(self:rndVec(1), r*vel))
		local radius = self:rnd(0.03, 0.05)
		local w = self:rnd(0.2, 0.5)
		ParticleReset()
		ParticleColor(w, w, w)
		ParticleAlpha(1)
		ParticleGravity(-10)
		ParticleRadius(radius, radius, "constant", 0, 0.2)
		ParticleSticky(0.2)
		ParticleStretch(0.0)
		ParticleTile(6)
		ParticleRotation(self:rnd(-20, 20), 0.0, "easeout")
		SpawnParticle(self.explosionPos, v, life)
	end
end

function explosionController:explosionSmall(pos)
	self.explosionPos = pos
	self:explosionSparks(10, 2)
	self:explosionDebris(25, 6)

	self.trails = {}
	for i=1, 8 do
		self:trailsAdd(pos, 5, 0.4, 0.1, 0.99, -10)
	end

	self.flash.age = 0
	self.flash.life = 0.1
	self.flash.intensity = 200
	
	self.light.age = 0
	self.light.life = 0.8
	self.light.intensity = 15
	
	self.fire.age = 0
	self.fire.life = 0.5
	self.fire.size = 0.2
	
	self.smoke.age = 0
	self.smoke.life = 1
	self.smoke.size = 0.5
	self.smoke.vel = 1
	self.smoke.gravity = 3
	self.smoke.amount = 2
end


function explosionController:explosionMedium(pos)
	self.explosionPos = pos
	self:explosionSparks(30, 3)
	self:explosionDebris(50, 7)

	self.trails = {}
	for i=1, 16 do
		self:trailsAdd(pos, 12, 0.4, 0.15, 0.97, -10)
	end

	self.flash.age = 0
	self.flash.life = 0.2
	self.flash.intensity = 500
	
	self.light.age = 0
	self.light.life = 1.0
	self.light.intensity = 30
	
	self.fire.age = 0
	self.fire.life = 0.6
	self.fire.size = 0.5

	self.smoke.age = 0
	self.smoke.life = 1.5
	self.smoke.size = 0.7
	self.smoke.vel = 1
	self.smoke.gravity = 2
	self.smoke.amount = 2
end


function explosionController:explosionLarge(pos)
	self.explosionPos = pos
	self:explosionSparks(50, 5)
	self:explosionDebris(100, 10)

	self.trails = {}
	for i=1, 8 do
		self:trailsAdd(pos, 12, 0.5, 0.2, 0.97, -10)
	end

	self.flash.age = 0
	self.flash.life = 0.4
	self.flash.intensity = 1000
	
	self.light.age = 0
	self.light.life = 1.2
	self.light.intensity = 50
	
	self.fire.age = 0
	self.fire.life = 0.7
	self.fire.size = 0.8
	
	self.smoke.age = 0
	self.smoke.life = 3
	self.smoke.size = 1.0
	self.smoke.gravity = -1
	self.smoke.vel = 8
	self.smoke.amount = 6
	
	--Sideways fast cloud
	ParticleReset()
	ParticleColor(0.8, 0.75, 0.7)
	ParticleRadius(0.3, 1.0)
	ParticleAlpha(1, 0, "easeout")
	ParticleDrag(0.2)
	for a=0, math.pi*2, 0.05 do
		local x = math.cos(a)*1
		local y = self:rnd(-0.1, 0.1)
		local z = math.sin(a)*1
		local d = VecNormalize(Vec(x, y, z))
		SpawnParticle(VecAdd(pos, d), VecScale(d, self:rnd(8,12)), self:rnd(0.5, 1.5))
	end
end


function explosionController:tick(dt)
	self:flashTick(self.explosionPos, dt)
	self:lightTick(self.explosionPos, dt)
end

function explosionController:pushExplosion(pos,strength)
	if strength >= 2 then
		self:explosionLarge(pos)
	elseif strength >= 1 then
		self:explosionMedium(pos)
	else
		self:explosionSmall(pos)
	end
	self:shockwave(pos,strength)
end


function explosionController:update(dt)
	self:trailsUpdate(dt)
	self:fireUpdate(self.explosionPos, dt)
	self:smokeUpdate(self.explosionPos, dt)
end

function explosionController:testFunc(dt)
	return "hello world"
end



-- strength = 2000	--Strength of shockwave impulse
-- maxDist = 15	--The maximum distance for bodies to be affected
-- maxMass = 1000	--The maximum mass for a body to be affected

function explosionController:shockwave(pos,power)
	local maxDist = power * 5
	local maxMass = power *5 * self.forceCoef

	local strength= power *10 * self.forceCoef
	--Get all physical and dynamic bodies in front of the tank
	local mi = VecAdd(pos, Vec(-maxDist/2, -1, -maxDist/2))
	local ma = VecAdd(pos, Vec(maxDist/2, 2, maxDist/2))
	
	QueryRequire("physical dynamic")
	local bodies = QueryAabbBodies(mi, ma)		
	--Loop through bodies and push them
	for i=1,#bodies do
		local b = bodies[i]

		--Compute body center point and distance
		local bmi, bma = GetBodyBounds(b)
		local bc = VecLerp(bmi, bma, 0.5)
		local dir = VecSub(bc, pos)
		local dist = VecLength(dir)
		dir = VecScale(dir, 1.0/dist)

		--Get body mass
		local mass = GetBodyMass(b)
		
		--Make sure direction is always pointing slightly upwards
		dir[2] = 0.5
		dir = VecNormalize(dir)	
		
		--Compute how much velocity to add
		local massScale = 1 - math.min(mass/self.maxMass, 1.0)
		local distScale = 1 - math.min(dist/maxDist, 1.0)
		local add = VecScale(dir, strength * massScale * distScale)

		ApplyBodyImpulse(b, bc, add)
	end
end