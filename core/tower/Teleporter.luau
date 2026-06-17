local assets = require "@core/assets"
local character = require "@libs/character"
local logger = require "@core/shared/logger"
const activation = require "@libs/activation"
const Attribute = require "@libs/attributes/Attribute"
local sounds = require "@libs/sounds"
local std = require "@libs/std"
local teleport = require "@libs/teleport"
const tweens = require "@libs/tweens"

local Teleporter = std.Mechanic {
	emoji = "🌀",
	name = "Teleporter",
	description = "When activated, teleports the activator to a destination matching it's Group.",
	instanceType = std.isA.BasePart(),

	debounce = std.LevelState(false),
	debouncedTeleporters = std.LevelState<<{ [TeleporterMechanic]: true }>> {},

	Group = std.Attribute("Group", std.gt.tag, ""),
	Cooldown = std.Attribute("Cooldown", std.gt.positiveNumber, 0),
	Teleport = teleport.useAttributes(),

	std.AttributeSection "Activation",
	Activation = activation.useAttributes(),

	std.AttributeSection "Seamless",
	Seamless = teleport.useSeamlessAttributes(),

	std.AttributeSection "Sound",
	Sound = sounds.useAttributes(),

	std.AttributeSection "Tween",
	Tween = tweens.useAttributes(),
}
export type TeleporterMechanic = std.Mechanic<typeof(Teleporter)>

function Teleporter.onActivate(self: typeof(Teleporter), teleporter: TeleporterMechanic, level: std.Level, event)
	local root = character.getMaybeHumanoidRootPart()
	if not root then return end

	if self.debounce:get(level) then return end

	teleporter.Activation.Enabled(teleporter, false)

	local group = teleporter:Group()
	if not group then return end

	local groupInstances = level:getGroupedInstances(group)
	local len = #groupInstances
	if len == 0 then return end

	self.debounce:set(level, true)
	self.Activation.Enabled(teleporter, false)
	teleporter.life:delay(teleporter:Cooldown(), Attribute.set :: any, self.Activation.Enabled, teleporter, true)

	math.randomseed(os.clock())
	local targetDestination = groupInstances[if len == 1 then 1 else math.random(1, len)]
	if not targetDestination:IsA "BasePart" then
		logger:Warn("Expected teleporter destination", targetDestination:GetFullName(), "to be a BasePart")
		return
	end

	if self.Sound.Play(teleporter) then
		sounds.playInstance(self.Sound, teleporter.instance, teleporter.instanceConfiguration, assets.sfx.teleport)
	end

	teleport.teleport {
		teleporter = teleporter.instance,
		teleporterConfiguration = teleporter.instanceConfiguration or teleporter.instance,
		teleporterLife = teleporter.life,

		target = root,
		destination = targetDestination,

		attributes = self.Teleport,
		seamlessAttributes = self.Seamless,
		tweenAttributes = self.Tween,
	}

	self.debounce:set(level, false)
end

return Teleporter
