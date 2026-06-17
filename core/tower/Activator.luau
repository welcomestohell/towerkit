const activation = require "@libs/activation"
const std = require "@libs/std"

const Activator = std.Mechanic {
	emoji = "👆",
	name = "Activator",
	description = "When activated, activates mechanics tagged with it's Group.",
	instanceType = std.gt.instanceTree { Target = std.gt.optional(std.isA.ObjectValue()) },

	Enabled = std.Attribute("Enabled", std.gt.boolean(), true),
	Cooldown = std.Attribute("Cooldown", std.gt.positiveNumber, 0),
	Group = std.Attribute("Group", std.gt.group, ""),

	std.AttributeSection "Activation",
	Activation = activation.useAttributes(),
}

export type ActivatorMechanic = std.Mechanic<typeof(Activator)>

function Activator.tryActivate(instance: Instance, level: std.Level)
	local mechanics = level.mechanicsByInstance[instance]
	if mechanics then
		for _, mechanic in mechanics :: { std.Mechanic<std.AnyMechanicImplementation> } do
			if type(mechanic.onActivate) == "function" then
				mechanic.onActivate(mechanic.implementation, mechanic :: any, level, { type = "Activator" })
			end
		end
	end
end

function Activator.onActivate(self: typeof(Activator), activator: ActivatorMechanic, level: std.Level)
	if not activator:Enabled() then return end

	self.Activation.Enabled(activator, false)

	local targetInstance = activator.instance.Target
	if targetInstance then self.tryActivate(targetInstance, level) end

	for _, grouped in level:getGroupedInstances(self:Group()) do
		self.tryActivate(grouped, level)
	end

	task.wait(activator:Cooldown())
	self.Activation.Enabled(activator, true)
end

return Activator
