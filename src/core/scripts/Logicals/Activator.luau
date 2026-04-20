local CollectionService = game:GetService("CollectionService")

local activation = require("@libs/activation")
local std = require("@libs/std")

--[=[
	@class Activator
	@tag Mechanic

	Activates the targeted instances when the mechanic itself is activated.
]=]
local Activator = std.Mechanic({})
export type ActivatorMechanic = std.Mechanic<typeof(Activator)>
Activator.basename = "Activator"
Activator.instanceType = std.gt.instanceTree({
	Target = std.gt.optional(std.isA.ObjectValue()),
})
Activator.debuggerEmoji = "👆"

Activator.Enabled = Activator:withEnabled()
Activator.Cooldown = Activator:attribute("Cooldown", std.gt.positiveNumber, 0)
Activator.TargetTag = Activator:attribute("TargetTag", std.gt.string(), "")

Activator:attributeSection("Activation")
Activator.Activation = activation.useAttributes(Activator)

function Activator.tryActivate(instance: Instance, level: std.Level)
	local mechanics = level.mechanicsByInstance[instance]
	if mechanics then
		for _, mechanic in mechanics :: { std.MechanicImplementation } do
			if type(mechanic.onActivate) == "function" then
				mechanic.onActivate(mechanic.implementation, mechanic :: any, level)
			end
		end
	end
end

function Activator.onActivate(self: typeof(Activator), activator: ActivatorMechanic, level: std.Level)
	if not activator:Enabled() then
		return
	end

	self.Activation.Enabled(activator, false)

	local targetInstance = activator.instance.Target
	if targetInstance then
		self.tryActivate(targetInstance, level)
	end

	local targetTag = self:TargetTag()
	if targetTag then
		for _, tagged in CollectionService:GetTagged(targetTag) do
			self.tryActivate(tagged, level)
		end
	end

	task.wait(activator:Cooldown())
	self.Activation.Enabled(activator, true)
end

return Activator
