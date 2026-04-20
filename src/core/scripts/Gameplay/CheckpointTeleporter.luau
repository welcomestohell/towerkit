local Checkpoint = require("./Checkpoint")
local activation = require("@libs/activation")
local character = require("@libs/character")
local functions = require("@libs/functions")
local sounds = require("@libs/sounds")
local std = require("@libs/std")
local teleport = require("@libs/teleport")
local tweens = require("@libs/tweens")

local CheckpointTeleporter = std.Mechanic({})
export type CheckpointTeleporterMechanic = std.Mechanic<typeof(CheckpointTeleporter)>
CheckpointTeleporter.basename = "CheckpointTeleporter"
CheckpointTeleporter.instanceType = std.isA.BasePart()
CheckpointTeleporter.debuggerEmoji = "⬅️"

CheckpointTeleporter.Cooldown = CheckpointTeleporter:attribute("Cooldown", std.gt.positiveNumber, 0)
CheckpointTeleporter.OnNoCheckpoint = CheckpointTeleporter:attribute(
	"OnNoCheckpoint",
	std.gt.unionLiterals2("DoNothing", "ReturnToSpawn"),
	functions.literal("DoNothing")
)

CheckpointTeleporter:attributeSection("Activation")
CheckpointTeleporter.Activation = activation.useAttributes(CheckpointTeleporter)

CheckpointTeleporter:attributeSection("Teleportation")
CheckpointTeleporter.Teleport = teleport.useAttributes(CheckpointTeleporter)

CheckpointTeleporter:attributeSection("Seamless")
CheckpointTeleporter.Seamless = teleport.useSeamlessAttributes(CheckpointTeleporter)

CheckpointTeleporter:attributeSection("Sound Effects")
CheckpointTeleporter.Sound = sounds.useAttributes(CheckpointTeleporter)

CheckpointTeleporter:attributeSection("Transition")
CheckpointTeleporter.Transition = tweens.useAttributes(CheckpointTeleporter)

function CheckpointTeleporter:onActivate(teleporter: CheckpointTeleporterMechanic, level: std.Level)
	local root = character.getMaybeHumanoidRootPart()
	if not root then
		return
	end

	local currentCheckpoint = Checkpoint.currentCheckpoint:get(level)
	local destination: BasePart, destinationConfiguration: Instance

	if currentCheckpoint then
		destination = currentCheckpoint.instance
		destinationConfiguration = currentCheckpoint.instanceConfiguration
	else
		local behavior = teleporter:OnNoCheckpoint()
		if behavior == "DoNothing" then
			return
		elseif behavior == "ReturnToSpawn" then
			destination = level.instance.SpawnCharacter
			destinationConfiguration = destination
		end
	end

	self.Activation.Enabled(teleporter, false)
	teleporter.life:delay(teleporter:Cooldown(), function(self: typeof(self), teleporter: typeof(teleporter))
		self.Activation.Enabled(teleporter, true)
	end, self, teleporter)

	if self.Sound.Play(teleporter) then
		sounds.playInstance(self.Sound, teleporter.instance, teleporter.instanceConfiguration, sounds.sfx.teleport)
	end

	teleport.teleport({
		teleporter = teleporter.instance,
		teleporterConfiguration = teleporter.instanceConfiguration or teleporter.instance,
		teleporterLife = teleporter.life,

		target = root,
		destination = destination,
		destinationConfiguration = destinationConfiguration,

		attributes = self.Teleport,
		seamlessAttributes = self.Seamless,
		tweenAttributes = self.Transition,
	})
end

return CheckpointTeleporter
