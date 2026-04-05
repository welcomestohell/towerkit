local ids = require("@libs/ids")
local properties = require("@libs/properties")
local std = require("@libs/std")
local tweens = require("@libs/tweens")

local CLASSES_TO_TOGGLE_ENABLED: { [string]: true } = {
	Beam = true,
	Constraint = true,
	ParticleEmitter = true,
	Fire = true,
	Sparkles = true,
	Smoke = true,
	Trail = true,
	UIStroke = true,
	UIGradient = true,
}

local CLASSES_TO_TWEEN: { [string]: string } = {
	BasePart = "Transparency",
	Decal = "Transparency",
	Texture = "Transparency",
	SelectionBox = "Transparency",
	SelectionSphere = "Transparency",
	Frame = "BackgroundTransparency",
	CanvasGroup = "GroupTransparency",
	TextLabel = "TextTransparency",
	ImageLabel = "ImageTransparency",
}

local ButtonEnabled = std.Mechanic({})
export type ButtonEnabledMechanic = std.Mechanic<typeof(ButtonEnabled)>

ButtonEnabled.instanceTag = "ButtonEnabled"
ButtonEnabled.instanceType = std.isA.Instance()
ButtonEnabled.debuggerEmoji = "💡"

ButtonEnabled.Enabled = ButtonEnabled:withEnabled()

ButtonEnabled.Id = ids.withAttribute(ButtonEnabled)
ButtonEnabled.besById = std.LevelState({} :: ids.MechanicsById<ButtonEnabledMechanic>)

ButtonEnabled:attributeSection("Properties")
-- TODO: itll probably be smarter to have AttributeGroups for these
ButtonEnabled.AffectsPropertyCollision = ButtonEnabled:attribute("AffectsPropertyCollision", std.gt.boolean(), true)
ButtonEnabled.AffectsPropertyTransparency =
	ButtonEnabled:attribute("AffectsPropertyTransparency", std.gt.boolean(), true)
ButtonEnabled.AffectsPropertyEnabled = ButtonEnabled:attribute("AffectsPropertyEnabled", std.gt.boolean(), true)
ButtonEnabled.TransparencyEnabled = ButtonEnabled:attribute("TransparencyEnabled", std.gt.constrainNumber(0, 1), 0)
ButtonEnabled.TransparencyDisabled = ButtonEnabled:attribute("TransparencyDisabled", std.gt.constrainNumber(0, 1), 0)

ButtonEnabled:attributeSection("Transitions")
ButtonEnabled.Transition = tweens.useAttributes(ButtonEnabled)

ButtonEnabled.CLASSES_TO_TOGGLE_ENABLED = CLASSES_TO_TOGGLE_ENABLED
ButtonEnabled.CLASSES_TO_TWEEN = CLASSES_TO_TWEEN

function ButtonEnabled.onStart(self: typeof(ButtonEnabled), be: ButtonEnabledMechanic, level: std.Level)
	ids.trackMechanic(level, be, be.besById)
	be:toggle()
end

function ButtonEnabled.toggle(be: ButtonEnabledMechanic)
	local enabled = not be:Enabled()
	be:Enabled(enabled)

	if be.instance:IsA("BasePart") and be:AffectsPropertyCollision() then
		properties.setUnsafe(be.instance, "CanCollide", enabled)
	end

	if be:AffectsPropertyEnabled() then
		for class in CLASSES_TO_TOGGLE_ENABLED do
			if be.instance:IsA(class) then
				properties.setUnsafe(be.instance, "Enabled", true)
				break
			end
		end
	end

	if be:AffectsPropertyTransparency() then
		for class, property in CLASSES_TO_TWEEN do
			if be.instance:IsA(class) then
				local transparency: number

				if enabled then
					transparency = if be.TransparencyEnabled:peek(be) == nil
						then be:TransparencyEnabled((be.instance :: any)[property] :: number)
						else be:TransparencyEnabled()
				else
					transparency = if be.TransparencyDisabled:peek(be) == nil
						then be:TransparencyDisabled((be.instance :: any)[property] :: number)
						else be:TransparencyDisabled()
				end

				local tweenConfiguration = tweens.configurationFromAttributes(be.Transition, be)
				tweens.play(be.instance, { [property] = transparency }, tweenConfiguration)

				return
			end
		end
	end
end

return ButtonEnabled
