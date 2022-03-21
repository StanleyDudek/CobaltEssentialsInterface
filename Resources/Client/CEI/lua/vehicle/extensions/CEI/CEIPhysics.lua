
local M = {}

local counter = 0
local physstart = 0

local physmult = 1

local physHandlerAdded = false

local function update(dtSim)
	if not playerInfo.firstPlayerSeated then
		return
	end
	if counter == 0 then 
		physstart = os.clock()
	end
	counter = counter + 1
	if counter == 2000 then
		counter = 0
		local physend = os.clock()
		local physdiff = physend - physstart
		physmult = 1 / physdiff
		obj:queueGameEngineLua("CEI.setPhysicsSpeed("..physmult..")")
	end
end

local function updateGFX(dt)
	if not physHandlerAdded and MPVehicleVE then
		MPVehicleVE.AddPhysUpdateHandler('CEIPhysics', M.update)
		physHandlerAdded = true
	end
end

M.update = update
M.updateGFX = updateGFX

return M
