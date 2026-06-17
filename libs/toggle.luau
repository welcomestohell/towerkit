const Attribute = require "@libs/attributes/Attribute"
const properties = require "@libs/properties"
const threadpool = require "@libs/threadpool"
const tweens = require "@libs/tweens"
const gt = require "@libs/vendor/gt"

const CLASSES_TO_TOGGLE_ENABLED: { [string]: true } = {
	Beam = true,
	Constraint = true,
	ParticleEmitter = true,
	Fire = true,
	Sparkles = true,
	Smoke = true,
	Trail = true,
	UIStroke = true,
	UIGradient = true,
	Light = true,
	Highlight = true,
}

const CLASSES_TO_TWEEN: { [string]: string } = {
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

const Enabled = Attribute.new("Enabled", gt.boolean(), false)
const Inverted = Attribute.new("Inverted", gt.boolean(), false)

const ToggleDescendants = Attribute.new("ToggleDescendants", gt.boolean(), false)
const ToggleDescendantsInheritAttributes = Attribute.new("ToggleDescendantsInheritAttributes", gt.boolean(), false)

const SetCollision = Attribute.new("SetCollision", gt.boolean(), true)
const SetTransparency = Attribute.new("SetTransparency", gt.boolean(), true)
const SetEnabled = Attribute.new("SetEnabled", gt.boolean(), true)

const TransparencyEnabled = Attribute.new("TransparencyEnabled", gt.constrainNumber(0, 1), 0)
const TransparencyDisabled = Attribute.new("TransparencyDisabled", gt.constrainNumber(0, 1), 1)

const Tween: tweens.TweenAttributes = {
	Duration = Attribute.new("ToggleDuration", gt.positiveNumber, 0.2),
	Style = Attribute.new("ToggleStyle", gt.enumOf(Enum.EasingStyle), Enum.EasingStyle.Quart),
	Direction = Attribute.new("ToggleDirection", gt.enumOf(Enum.EasingDirection), Enum.EasingDirection.Out),
}

const function toggleInstance(enabled: boolean, instance: Instance, instanceConfiguration: Instance?)
	instanceConfiguration = instanceConfiguration or instance

	if Inverted(instanceConfiguration) then enabled = not enabled end
	Enabled(instanceConfiguration, enabled)

	if instance:IsA "BasePart" and SetCollision(instanceConfiguration) then instance.CanCollide = enabled end

	if SetEnabled(instanceConfiguration) then
		for className in CLASSES_TO_TOGGLE_ENABLED do
			if instance:IsA(className) then
				properties.setUnsafe(instance, "Enabled", enabled)
				break
			end
		end
	end

	if SetTransparency(instanceConfiguration) then
		const goalTransparency = if enabled
			then TransparencyEnabled(instanceConfiguration)
			else TransparencyDisabled(instanceConfiguration)

		const goalProperties: { [string]: unknown } = {}
		for className, propertyToTween in CLASSES_TO_TWEEN do
			if instance:IsA(className) then goalProperties[propertyToTween] = goalTransparency end
		end

		const tweenConfiguration = tweens.configurationFromAttributes(Tween, instanceConfiguration)
		tweens.play(instance, goalProperties, tweenConfiguration)
	end

	if ToggleDescendants(instanceConfiguration) then
		instanceConfiguration = if ToggleDescendantsInheritAttributes(instanceConfiguration)
			then instanceConfiguration
			else nil

		for _, descendant in instance:GetDescendants() do
			threadpool.spawn(toggleInstance, enabled, descendant, instanceConfiguration)
		end
	end
end

return table.freeze {
	CLASSES_TO_TOGGLE_ENABLED = CLASSES_TO_TOGGLE_ENABLED,
	CLASSES_TO_TWEEN = CLASSES_TO_TWEEN,

	Enabled = Enabled,
	Inverted = Inverted,
	SetCollision = SetCollision,
	SetTransparency = SetTransparency,
	SetEnabled = SetEnabled,
	TransparencyEnabled = TransparencyEnabled,
	TransparencyDisabled = TransparencyDisabled,

	toggleInstance = toggleInstance,
}
