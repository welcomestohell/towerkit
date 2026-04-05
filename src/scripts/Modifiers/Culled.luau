local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()

local std = require("@libs/std")

--[=[
	@class Culled
	@tag Mechanic

	Culled disables the instance when it's distant during gameplay.

	Culled is ideal for optimizing physic objects where you'll like it to freeze
	when far away.

	Culled can be triggered by distance, or by camera culling. 
]=]
local Culled = std.Mechanic({})
export type CulledMechanic = std.Mechanic<typeof(Culled)>

Culled.instanceTag = "Culled"
Culled.instanceType = std.isA.BasePart()
Culled.debuggerEmoji = "😶"

Culled.Enabled = Culled:withEnabled()

Culled:attributeSection("Distance")
Culled.MinimumDistance = Culled:attribute("MinimumDistance", std.gt.number(), 100)
Culled.MaximumDistance = Culled:attribute("MaximumDistance", std.gt.number(), math.huge)

function Culled.onPreSimulation(self: typeof(Culled), deltaTime: number, level: std.Level)
	local mechanics = level:getMechanics(self)
	local countMechanics = #mechanics

	if countMechanics == 0 then
		return
	end

	for _, culled in mechanics do
		if not culled:Enabled() then
			continue
		end

		local instance = culled.instance

		local distance = localPlayer:DistanceFromCharacter(instance.Position)
		local shouldAnchor = distance >= culled:MinimumDistance() and distance <= culled:MaximumDistance()

		if instance.Anchored ~= shouldAnchor then
			instance.Anchored = shouldAnchor
		end
	end
end

return Culled
