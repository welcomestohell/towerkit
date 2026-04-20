local std = require("@libs/std")

local Conveyor = std.Mechanic({})
export type ConveyorMechanic = std.Mechanic<typeof(Conveyor)>
Conveyor.basename = "Conveyor"
Conveyor.instanceType = std.isA.BasePart()
Conveyor.debuggerEmoji = "🛣️"

Conveyor.Speed = Conveyor:attribute("Speed", std.gt.positiveNumber, 0)
Conveyor.SynchronizeBeams = Conveyor:attribute("SynchronizeBeams", std.gt.boolean(), false)

function Conveyor:onPreSimulation(deltaTime: number, level: std.Level)
	for _, conveyor in level:getMechanics(Conveyor) do
		local speed: number = conveyor:Enabled() and conveyor:Speed() or 0
		conveyor.instance.AssemblyLinearVelocity = conveyor.instance.CFrame.LookVector * speed

		if conveyor:SynchronizeBeams() then
			for _, beam in conveyor.instance:GetDescendants() :: { Beam } do
				if beam.Name == "ConveyorBeam" and beam.ClassName == "Beam" then
					beam.TextureSpeed = speed / beam.TextureLength
				end
			end
		end
	end
end

return Conveyor
