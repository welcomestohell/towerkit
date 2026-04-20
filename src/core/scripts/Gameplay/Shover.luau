local std = require("@libs/std")
local threadpool = require("@libs/threadpool")

local Shover = std.Mechanic({})
export type ShoverMechanic = std.Mechanic<typeof(Shover)>
Shover.basename = "Shover"
Shover.instanceType = std.gt.instanceTree({
	ShoverConstraint = std.isA.PrismaticConstraint(),
})
Shover.debuggerEmoji = "🤜"

type ShoverDirection = "In" | "Out"
type ShoverDirectionAttributes = {
	delay: std.Attribute<number>,
	power: std.Attribute<number>,
}

Shover.threads = std.LevelState({} :: { [ShoverMechanic]: thread })
Shover.directions = {} :: { [ShoverDirection]: ShoverDirectionAttributes }

Shover:attributeSection("In")
Shover.directions.In = {
	delay = Shover:attribute("InDelay", std.gt.positiveNumber, 1),
	power = Shover:attribute("InPower", std.gt.positiveNumber, 0),
}

Shover:attributeSection("Out")
Shover.directions.Out = {
	delay = std.Attribute("OutDelay", std.gt.positiveNumber, 1),
	power = std.Attribute("OutPower", std.gt.positiveNumber, 0),
}

function Shover.shove(shover: ShoverMechanic, direction: ShoverDirection)
	local attributes: ShoverDirectionAttributes = Shover.directions[direction]

	task.wait(attributes.delay(shover))

	if shover:Enabled() then
		local power = attributes.power(shover)
		local constraint = shover.instance.ShoverConstraint
		constraint.LinearResponsiveness = power
		constraint.Speed = power
		constraint.TargetPosition = if direction == "Out" then shover.UpperLimit else 0
	end
end

function Shover:onPreSimulation(_, level: std.Level)
	local threads = Shover.threads:get(level)
	for _, shover: ShoverMechanic in level:getMechanics(Shover) do
		if not threads[shover] then
			threads[shover] = level.life:add(threadpool.spawn(function(shover: ShoverMechanic)
				while shover:Enabled() do
					shover:shove("In")
					shover:shove("Out")
				end
			end, shover))
		end
	end
end

return Shover
