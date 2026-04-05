local Checkpoint = require("./Checkpoint")
local activation = require("@libs/activation")
local std = require("@libs/std")

local CheckpointResetter = std.Mechanic({})
export type CheckpointResetterMechanic = std.Mechanic<typeof(CheckpointResetter)>
CheckpointResetter.instanceTag = "CheckpointResetter"
CheckpointResetter.instanceType = std.isA.BasePart()
CheckpointResetter.debuggerEmoji = "🔄"

CheckpointResetter.Cooldown = Checkpoint:attribute("CheckpointResetter", std.gt.positiveNumber, 0)

CheckpointResetter:attributeSection("Activation")
CheckpointResetter.Activation = activation.useAttributes(CheckpointResetter)

function CheckpointResetter:onActivate(resetter: CheckpointResetterMechanic, level: std.Level)
	self.Activation.Enabled(resetter, false)
	resetter.life:delay(resetter:Cooldown(), function(self: typeof(self), resetter: typeof(resetter))
		self.Activation.Enabled(resetter, true)
	end, self, resetter)

	Checkpoint.currentCheckpoint:set(level, nil)
end

return CheckpointResetter
