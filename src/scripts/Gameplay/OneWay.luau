local character = require("@libs/character")
local std = require("@libs/std")

local OneWay = std.Mechanic({})
export type OneWayMechanic = std.Mechanic<typeof(OneWay)>
OneWay.instanceTag = "OneWay"
OneWay.instanceType = std.isA.BasePart()
OneWay.debuggerEmoji = "⛔"

OneWay.Offset = OneWay:attribute("Offset", std.gt.CFrame(), CFrame.identity)

function OneWay:onPreSimulation(deltaTime: number, level: std.Level)
	local root = character.getMaybeHumanoidRootPart()
	if not root then
		return
	end

	local rootPivot = root:GetPivot()
	for _, platform in level:getMechanics(OneWay) do
		local instance: BasePart = platform.instance
		local enabled: boolean = platform:Enabled()

		if enabled then
			local _offset: CFrame = platform:Offset()

			local partPivot = instance:GetPivot()
			local _upVector = partPivot.UpVector

			instance.CanCollide = rootPivot.Position.Y > partPivot.Position.Y
			-- this just breaks??? "invalid argument #2 (Vector3 expected, got nil)"
			--  upVector:Dot(
			-- 	CFrame.lookAt(
			-- 		(partPivot * (CFrame.new(Vector3.yAxis * (instance.Size.Y * 0.5)) * offset)).Position, -- breaks around here
			-- 		(rootPivot * CFrame.new(0, -math.sign(upVector:Dot(Vector3.yAxis)), 0)).Position
			-- 	).LookVector
			-- ) > 0
		else
			instance.CanCollide = false
		end
	end
end

return OneWay
