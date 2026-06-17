-- TODO: this lib sucks and should be revamped asap

local ContentProvider = game:GetService "ContentProvider"
local Debris = game:GetService "Debris"
local SoundService = game:GetService "SoundService"

const Attribute = require "@libs/attributes/Attribute"
const resolveInstance = require "@libs/core/resolveInstance"
local audios = { sfx = {} } --require("@core/shared/generated/audios")
local gt = require "@libs/vendor/gt"

export type SoundConfiguration = {
	id: string?,
	asset: string?,
	volume: number,
	speed: number,
	spatial: boolean,
	timeStart: number,
	timeEnd: number,
}

type AsphaltAsset = { [string]: AsphaltAsset } | string

local DESTROY_AFTER_SECONDS = 5
local FALLBACK_ID = "rbxassetid://0"

local assetPaths: { [string]: string } = {}

local function useAssets(assets: { [string]: AsphaltAsset }, cwd: string?)
	cwd = cwd or ""

	for key, asset in assets do
		local path = cwd .. "/" .. key
		if typeof(asset) == "table" then
			useAssets(asset, path)
		else
			assetPaths[path] = asset
		end
	end
end

local function useAttributes(basename: string?)
	basename = basename or "Sound"

	local attributes = {}
	attributes.Basename = Attribute.new(basename .. "Basename", gt.string(), basename)
	attributes.Play = Attribute.new("Play" .. basename, gt.boolean(), true)
	attributes.Id = Attribute.new(basename .. "Id", gt.optional(gt.string()), nil)
	attributes.Asset = Attribute.new(basename .. "Asset", gt.optional(gt.string()), nil)
	attributes.Volume = Attribute.new(basename .. "Volume", gt.positiveNumber, 0.5)
	attributes.Speed = Attribute.new(basename .. "Speed", gt.positiveNumber, 1)
	attributes.Spatial = Attribute.new(basename .. "Spatial", gt.boolean(), true)
	attributes.TimeStart = Attribute.new(basename .. "TimeStart", gt.positiveNumber, 0)
	attributes.TimeEnd = Attribute.new(basename .. "TimeEnd", gt.number(), -1)

	return attributes
end

export type SoundAttributes = typeof(useAttributes(nil :: any))

local function configurationFromAttributes(
	attributes: SoundAttributes,
	instance: resolveInstance.InstanceLike
): SoundConfiguration
	return {
		id = attributes.Id(instance),
		asset = attributes.Asset(instance),
		volume = attributes.Volume(instance),
		speed = attributes.Speed(instance),
		spatial = attributes.Spatial(instance),
		timeStart = attributes.TimeStart(instance),
		timeEnd = attributes.TimeEnd(instance),
	}
end

local function idFromConfiguration(configuration: SoundConfiguration): string?
	return configuration.id or configuration.asset and assetPaths[configuration.asset]
end

local function soundFromConfiguration(configuration: SoundConfiguration, fallbackId: string?)
	local sound = Instance.new "Sound"
	sound.SoundId = idFromConfiguration(configuration) or fallbackId or FALLBACK_ID
	sound.PlaybackSpeed = configuration.speed
	sound.Volume = configuration.volume
	sound.TimePosition = configuration.timeStart
	return sound
end

local function playInstance(
	attributes: SoundAttributes,
	instance: Instance,
	instanceConfiguration: Instance?,
	fallbackId: string?
)
	instanceConfiguration = instanceConfiguration or instance
	local sound: Sound? = nil

	local pointer = instanceConfiguration:FindFirstChild(attributes.Basename(instanceConfiguration))
	if pointer then
		if pointer:IsA "ObjectValue" then pointer = pointer.Value or pointer end

		if pointer:IsA "Sound" then sound = sound end
	end

	local configuration = configurationFromAttributes(attributes, instanceConfiguration)
	sound = sound or soundFromConfiguration(configuration, fallbackId)

	sound.Parent = if attributes.Spatial(instanceConfiguration) then instance else SoundService

	sound:Play()
	-- TODO: account for TimeEnd
	Debris:AddItem(sound, sound.TimeLength + DESTROY_AFTER_SECONDS)

	return sound
end

-- FIXME: Mechanic<any> type doesn't work in practice ???
-- local function playMechanic(attributes: SoundAttributes, mechanic: Mechanic.Mechanic, fallbackId: string?)
local function playMechanic(attributes: SoundAttributes, mechanic: any, fallbackId: string?)
	return playInstance(attributes, mechanic.instance, mechanic.instanceConfiguration or mechanic.instance, fallbackId)
end

local function preloadAssets()
	local assets: { Sound } = {}
	for path, asset in assetPaths do
		local sound = Instance.new "Sound"
		sound.Name = path .. " (preload)"
		sound.SoundId = asset
		sound.Parent = SoundService
		table.insert(assets, sound)
	end

	ContentProvider:PreloadAsync(assets)

	for _, instance in assets do
		instance:Destroy()
	end
end

return table.freeze {
	sfx = table.freeze(table.clone(audios.sfx)),
	assetPaths = assetPaths,
	useAssets = useAssets :: <T>(assets: T) -> (),
	useAttributes = useAttributes,
	configurationFromAttributes = configurationFromAttributes,
	idFromConfiguration = idFromConfiguration,
	soundFromConfiguration = soundFromConfiguration,
	playInstance = playInstance,
	playMechanic = playMechanic,
	preloadAssets = preloadAssets,
}
