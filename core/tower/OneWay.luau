local character = require "@libs/character"
local std = require "@libs/std"

local OneWay = std.Mechanic {
	emoji = "⛔",
	name = "OneWay",
	description = "Only solid for the player from the topmost side.",
	instanceType = std.isA.BasePart(),

	Enabled = std.Attribute("Enabled", std.gt.boolean(), true),
	Offset = std.Attribute("Offset", std.gt.CFrame(), CFrame.identity),
}

export type OneWayMechanic = std.Mechanic<typeof(OneWay)>

function OneWay:onPreSimulation(deltaTime: number, level: std.Level)
	local root = character.getMaybeHumanoidRootPart()
	if not root then return end

	local rootPivot = root:GetPivot()
	for _, platform: OneWayMechanic in level:getMechanics(OneWay) do
		local instance: BasePart = platform.instance
		local enabled: boolean = platform:Enabled()

		if enabled then
			local offset: CFrame = platform:Offset()

			local partPivot = instance:GetPivot()
			local upVector = partPivot.UpVector

			instance.CanCollide = upVector:Dot(
				CFrame.lookAt(
					(partPivot * (CFrame.new(Vector3.yAxis * (instance.Size.Y * 0.5)) * offset)).Position,
					(rootPivot * CFrame.new(0, -math.sign(upVector:Dot(Vector3.yAxis)), 0)).Position
				).LookVector
			) > 0
		else
			instance.CanCollide = false
		end
	end
end

return OneWay
