local TweenService = game:GetService("TweenService")

local Attribute = require("./Attribute")
local Mechanic = require("./Mechanic")
local gt = require("./gt")

export type TweenConfiguration = {
	duration: number?,
	style: Enum.EasingStyle?,
	direction: Enum.EasingDirection?,
	repeatCount: number?,
	isReversed: boolean?,
	delayDuration: number?,
}

export type TweenAttributes = {
	Duration: Attribute.Attribute<number>,
	Style: Attribute.Attribute<Enum.EasingStyle>,
	Direction: Attribute.Attribute<Enum.EasingDirection>,
}

local isEasingStyle = gt.build(gt.enumOf(Enum.EasingStyle) :: Enum.EasingStyle)
local isEasingDirection = gt.build(gt.enumOf(Enum.EasingDirection) :: Enum.EasingDirection)

local function useAttributes(implementation: Mechanic.MechanicImplementationLike, prefix: string?): TweenAttributes
	local prefix = prefix or "Transition"

	local attributes = {}
	attributes.Duration = implementation:attribute(prefix .. "Duration", gt.positiveNumber, 0)
	attributes.Style = implementation:attribute(prefix .. "Style", isEasingStyle:type(), Enum.EasingStyle.Linear)
	attributes.Direction =
		implementation:attribute(prefix .. "Direction", isEasingDirection:type(), Enum.EasingDirection.Out)

	return attributes
end

local function configurationFromAttributes(
	attributes: TweenAttributes,
	instance: Attribute.ResolvableInstance
): TweenConfiguration
	return {
		duration = attributes.Duration(instance),
		style = attributes.Style(instance),
		direction = attributes.Direction(instance),
	}
end

local function tweenInfoFromConfiguration(configuration: TweenConfiguration)
	return TweenInfo.new(
		configuration.duration or 0,
		configuration.style or Enum.EasingStyle.Linear,
		configuration.direction or Enum.EasingDirection.Out,
		configuration.repeatCount or 0,
		not not configuration.isReversed,
		configuration.delayDuration or 0
	)
end

local function play(instance: Instance, propertyTable: { [string]: unknown }, configuration: TweenConfiguration?)
	local tweenInfo = tweenInfoFromConfiguration(configuration or {})

	if tweenInfo.Time > 0 then
		local tween = TweenService:Create(instance, tweenInfo, propertyTable)
		tween.Completed:Once(function()
			tween:Destroy()
		end)

		tween:Play()
	else
		for property, value in propertyTable do
			(instance :: any)[property] = value
		end
	end
end

local function playAlways(instance: Instance, propertyTable: { [string]: unknown }, configuration: TweenConfiguration?)
	local tweenInfo = tweenInfoFromConfiguration(configuration or {})

	local tween = TweenService:Create(instance, tweenInfo, propertyTable)
	tween.Completed:Once(function()
		tween:Destroy()
	end)

	tween:Play()
	return tween
end

local function playFromAttributes(instance: Instance, propertyTable: { [string]: unknown }, attributes: TweenAttributes)
	play(instance, propertyTable, configurationFromAttributes(attributes, instance))
end

local function playAlwaysFromAttributes(
	instance: Instance,
	propertyTable: { [string]: unknown },
	attributes: TweenAttributes
)
	return playAlways(instance, propertyTable, configurationFromAttributes(attributes))
end

return table.freeze {
	useAttributes = useAttributes,
	configurationFromAttributes = configurationFromAttributes,
	tweenInfoFromConfiguration = tweenInfoFromConfiguration,

	play = play,
	playAlways = playAlways,
	playFromAttributes = playFromAttributes,
	playAlwaysFromAttributes = playAlwaysFromAttributes,
}
