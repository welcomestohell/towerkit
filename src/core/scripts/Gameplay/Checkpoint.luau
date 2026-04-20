local Signal = require("@pkgs/Signal")
local activation = require("@libs/activation")
local sounds = require("@libs/sounds")
local std = require("@libs/std")

local Checkpoint = std.Mechanic({})
export type CheckpointMechanic = std.Mechanic<typeof(Checkpoint)>
Checkpoint.basename = "Checkpoint"
Checkpoint.instanceType = std.isA.BasePart()
Checkpoint.debuggerEmoji = "🚩"

Checkpoint.Cooldown = Checkpoint:attribute("Cooldown", std.gt.positiveNumber, 0)
Checkpoint.Persistent = Checkpoint:attribute("Persistent", std.gt.boolean(), false)

Checkpoint:attributeSection("Activation")
Checkpoint.Activation = activation.useAttributes(Checkpoint)

Checkpoint:attributeSection("Sounds")
Checkpoint.Sound = sounds.useAttributes(Checkpoint)

Checkpoint.currentCheckpoint = std.LevelState(nil :: CheckpointMechanic?)
-- TODO: LevelSignal class?
Checkpoint.onUpdated = Signal.new()
Checkpoint.debounce = std.LevelState(false)

function Checkpoint.onActivate(self: typeof(Checkpoint), checkpoint: CheckpointMechanic, level: std.Level)
	local currentCheckpoint = self.currentCheckpoint:get(level)
	if currentCheckpoint == checkpoint then
		return
	end

	self.currentCheckpoint:set(level, checkpoint)
	self.onUpdated:Fire(level, checkpoint)
	if self.Sound.Play(checkpoint) then
		sounds.playInstance(self.Sound, checkpoint.instance, checkpoint.instanceConfiguration, sounds.sfx.button)
	end

	self.Activation.Enabled(checkpoint, false)
	checkpoint.life:delay(checkpoint:Cooldown(), function(self: typeof(self), checkpoint: typeof(checkpoint))
		self.Activation.Enabled(checkpoint, true)
	end, self, checkpoint)
end

return Checkpoint
