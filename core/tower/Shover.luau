local std = require "@libs/std"

local Shover = std.Mechanic {
	emoji = "🤜",
	name = "Shover",
	description = "Periodically shoves in and out with knockback.",
	instanceType = std.isA.PrismaticConstraint(),

	Enabled = std.Attribute("Enabled", std.gt.boolean(), true),
	directions = {
		In = {
			std.AttributeSection "In",
			delay = std.Attribute("InDelay", std.gt.positiveNumber, 1),
			power = std.Attribute("InPower", std.gt.positiveNumber, 0),
		},
		Out = {
			std.AttributeSection "Out",
			delay = std.Attribute("OutDelay", std.gt.positiveNumber, 1),
			power = std.Attribute("OutPower", std.gt.positiveNumber, 0),
		},
	},
}

export type ShoverMechanic = std.Mechanic<typeof(Shover)>

type ShoverDirection = "In" | "Out"
type ShoverDirectionAttributes = {
	delay: std.Attribute<number>,
	power: std.Attribute<number>,
}

function Shover.shove(shover: ShoverMechanic, direction: ShoverDirection)
	local attributes: ShoverDirectionAttributes = Shover.directions[direction]

	task.wait(attributes.delay(shover))

	if shover:Enabled() then
		local power = attributes.power(shover)
		local constraint = shover.instance
		constraint.LinearResponsiveness = power
		constraint.Speed = power
		constraint.TargetPosition = if direction == "Out" then shover.instance.UpperLimit else 0
	end
end

function Shover:onStart(shover: ShoverMechanic, level: std.Level)
	repeat
		shover:shove "In"
		shover:shove "Out"
	until shover.life.destroyed
end

return Shover
