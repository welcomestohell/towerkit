local TweenService = game:GetService "TweenService"

local Attribute = require "@libs/attributes/Attribute"
const resolveInstance = require "@libs/core/resolveInstance"
local gt = require "@libs/vendor/gt"

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

local function useAttributes(basename: string?): TweenAttributes
	basename = basename or "Tween"
	return {
		Duration = Attribute.new(basename .. "Duration", gt.positiveNumber, 0),
		Style = Attribute.new(basename .. "Style", gt.enumOf(Enum.EasingStyle), Enum.EasingStyle.Linear),
		Direction = Attribute.new(basename .. "Direction", gt.enumOf(Enum.EasingDirection), Enum.EasingDirection.Out),
	}
end

local function configurationFromAttributes(
	attributes: TweenAttributes,
	instance: resolveInstance.InstanceLike
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

local function playFromAttributes(
	instance: Instance,
	propertyTable: { [string]: unknown },
	attributes: TweenAttributes,
	instanceConfiguration: Instance?
)
	play(instance, propertyTable, configurationFromAttributes(attributes, instanceConfiguration or instance))
end

local function playAlwaysFromAttributes(
	instance: Instance,
	propertyTable: { [string]: unknown },
	attributes: TweenAttributes,
	instanceConfiguration: Instance?
)
	return playAlways(
		instance,
		propertyTable,
		configurationFromAttributes(attributes, instanceConfiguration or instance)
	)
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
