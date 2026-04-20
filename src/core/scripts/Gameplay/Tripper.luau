local character = require("@libs/character")
local std = require("@libs/std")

local Tripper = std.Mechanic({})
export type TripperMechanic = std.Mechanic<typeof(Tripper)>

Tripper.basename = "Tripper"
Tripper.instanceType = std.isA.BasePart()
Tripper.debuggerEmoji = "🧀"

Tripper.Cooldown = Tripper:attribute("Cooldown", std.gt.positiveNumber, 0)

Tripper.debounced = {} :: { [TripperMechanic]: true }

function Tripper.undebounce(self: typeof(Tripper), tripper: TripperMechanic)
	self.debounced[tripper] = nil
end

function Tripper.onStart(self: typeof(Tripper), tripper: TripperMechanic)
	tripper.life:add(function()
		self:undebounce(tripper)
	end)
end

function Tripper.onActivate(self: typeof(Tripper), tripper: TripperMechanic)
	local humanoid = character.getMaybeHumanoid() :: Humanoid
	humanoid.Sit = true
	Tripper.debounced[tripper] = true
	task.delay(tripper:Cooldown(), self.undebounce, self, tripper)
end

return Tripper
