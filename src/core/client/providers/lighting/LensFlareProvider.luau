-- Based on LensFlare module by gluGPU:
-- https://devforum.roblox.com/t/lens-flare-system-easily-usable-by-builders-or-scripters/4021857/31

local prvd = require("@core/shared/prvdmwrong/prvdmwrong")
local Attribute = require("@libs/Attribute")
local gt = require("@libs/gt")
local Life = require("@libs/memory/Life")
local Charm = require("@pkgs/Charm")

local LensFlareProvider = {
	LENS_FLARE_TAG = "LensFlare",
	LensFlareStyle = Attribute.new("LensFlareStyle", gt.unionLiterals2("Default", "SmallLight"), "Default"),
	LensFlareDistance = Attribute.new("LensFlareDistance", gt.positiveNumber, 0),
	LensFlareStrength = Attribute.new("LensFlareStrength", gt.constrainNumber(0, 1), 0),

	ColorBlend = Attribute.new("ColorBlend", gt.constrainNumber(0, 1), 0),
	Position = Attribute.new("Position", gt.Vector3(), Vector3.one),
	PositionMultiplier = Attribute.new("PositionMultiplier", gt.number(), 1),
	Rotates = Attribute.new("Rotates", gt.boolean(), false),
	SizeFade = Attribute.new("SizeFade", gt.NumberSequence, NumberSequence.new(1)),
	SquashFade = Attribute.new("SquashFade", gt.NumberSequence, NumberSequence.new(0)),
	TransparencyFade = Attribute.new("TransparencyFade", gt.NumberSequence, NumberSequence.new(0)),

	enabled = Charm.atom(true),

	numberOfRaycasts = Charm.atom(5),
	raycastRadius = Charm.atom(7),
	transparencyThreshold = Charm.atom(0.66),

	sunAngleThreshold = Charm.atom(30),
	sunBrightnessThreshold = Charm.atom(2.5),
	sunExposureAdjustment = Charm.atom(2.25),
	sunExposureTime = Charm.atom(2),
}
export type LensFlareProvider = typeof(LensFlareProvider)

function LensFlareProvider.onInit(self: LensFlareProvider)
	self.life = Life.new()
end

function LensFlareProvider.onStart(self: LensFlareProvider) end

return prvd(LensFlareProvider)
