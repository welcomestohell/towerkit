local TeleporterDestination = require("./TeleporterDestination")
local activation = require("@libs/activation")
local character = require("@libs/character")
local sounds = require("@libs/sounds")
local std = require("@libs/std")
local teleport = require("@libs/teleport")
local tweens = require("@libs/tweens")

local Teleporter = std.Mechanic({})
export type TeleporterMechanic = std.Mechanic<typeof(Teleporter)>

Teleporter.instanceTag = "Teleporter"
Teleporter.instanceType = std.isA.BasePart()
Teleporter.debuggerEmoji = "🌀"

Teleporter.Id = Teleporter:attribute("Id", std.gt.optional(std.gt.string()), nil)
Teleporter.Cooldown = Teleporter:attribute("Cooldown", std.gt.positiveNumber, 0)
Teleporter.Teleport = teleport.useAttributes(Teleporter)

Teleporter:attributeSection("Seamless")
Teleporter.Seamless = teleport.useSeamlessAttributes(Teleporter)

Teleporter:attributeSection("Transitions")
Teleporter.Transition = tweens.useAttributes(Teleporter)

Teleporter:attributeSection("Sound")
Teleporter.Sound = sounds.useAttributes(Teleporter)

Teleporter.debounce = false
Teleporter.debouncedTeleporters = {} :: { [TeleporterMechanic]: true }
Teleporter.activation = activation.useAttributes(Teleporter)

function Teleporter.onActivate(self: typeof(Teleporter), teleporter: TeleporterMechanic, level: std.Level)
	local root = character.getMaybeHumanoidRootPart()
	if not root then
		return
	end

	if Teleporter.debounce or Teleporter.debouncedTeleporters[teleporter] then
		return
	end

	teleporter.activation.Enabled(teleporter, false)

	local allDestinations = TeleporterDestination.destinationsById:get(level)[teleporter.Id:assert(teleporter)]
	if not allDestinations then
		return
	end

	local len = #allDestinations
	if len == 0 then
		return
	end

	self.debounce = true
	self.debouncedTeleporters[teleporter] = true
	self.activation.Enabled(teleporter, false)
	task.delay(teleporter:Cooldown(), function(teleporter)
		self.debouncedTeleporters[teleporter] = nil
		self.activation.Enabled(teleporter, true)
	end, teleporter)

	math.randomseed(os.clock())
	local targetDestination = allDestinations[if len == 1 then 1 else math.random(1, len)]

	if self.Sound.Play(teleporter) then
		sounds.playInstance(self.Sound, teleporter.instance, teleporter.instanceConfiguration, sounds.sfx.teleport)
	end

	teleport.teleport {
		teleporter = teleporter.instance,
		teleporterConfiguration = teleporter.instanceConfiguration or teleporter.instance,
		teleporterLife = teleporter.life,

		target = root,
		destination = targetDestination.instance,
		destinationConfiguration = targetDestination.instanceConfiguration,

		attributes = self.Teleport,
		seamlessAttributes = self.Seamless,
		tweenAttributes = self.Transition,
	}

	self.debounce = false
end

return Teleporter
