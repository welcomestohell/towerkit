local CollectionService = game:GetService("CollectionService")
local ServerStorage = game:GetService("ServerStorage")
local StarterGui = game:GetService("StarterGui")
local StarterPlayer = game:GetService("StarterPlayer")
local TeleportService = game:GetService("TeleportService")
local Workspace = game:GetService("Workspace")

local Level = require("@libs/Level")
local Log = require("@libs/Log")
local PlayerInstanceLoader = require("@server/PlayerInstanceLoader")
local net = require("@server/generated/net")
local prvd = require("@shared/prvdmwrong/prvdmwrong")

local TOWER_FALLBACK_TAG = "Welcome To Hell Kit Tower"

local NO_TOWER_ERROR = `\
    No tower found, make sure you have a "Kit" tower under \
    the Workspace, or tag your tower with the "{TOWER_FALLBACK_TAG}" tag.\
`

local DEFAULTS: { [Instance]: { [string]: unknown } } = {
	[StarterGui] = { ScreenOrientation = Enum.ScreenOrientation.LandscapeSensor },
	[StarterPlayer] = { AutoJumpEnabled = false, CharacterUseJumpPower = true },
}

local KitServerProvider = {}
export type KitServerProvider = typeof(KitServerProvider)
KitServerProvider.log = Log.new(KitServerProvider)
KitServerProvider.decorationsLoader = PlayerInstanceLoader.new(15)
KitServerProvider.mechanicLoader = PlayerInstanceLoader.new(15)

local function getTower(): Instance?
	return Workspace:FindFirstChild("Kit") or CollectionService:GetTagged(TOWER_FALLBACK_TAG)[1]
end

local function storeOrDefault(fromParent: Instance, childName: string): Instance
	local child = fromParent:FindFirstChild(childName) :: Instance
	if not child then
		child = Instance.new("Folder")
		child.Name = childName
	end
	child.Parent = ServerStorage
	return child
end

function KitServerProvider.bootstrapTower(self: KitServerProvider, tower: Level.LevelInstance)
	local mechanics, decorations = storeOrDefault(tower, "Mechanics"), storeOrDefault(tower, "Decorations")

	net.getTower.on(function(): Instance
		return tower
	end)

	net.loadMechanics.on(function(player: Player): Instance
		return self.mechanicLoader:cloneToPlayer(player, mechanics)
	end)

	net.loadDecorations.on(function(player: Player): Instance
		return self.decorationsLoader:cloneToPlayer(player, decorations)
	end)

	net.rejoin.on(function(player)
		TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, player)
	end)
end

function KitServerProvider.onStart(self: KitServerProvider)
	for instance, defaults in DEFAULTS do
		for property, expectedValue in defaults do
			local realValue = (instance :: any)[property]
			if realValue ~= expectedValue then
				self.log:warn(`To align with Welcome To Hell, {instance}.{property} has been set to {realValue}.`);
				(instance :: any)[property] = expectedValue
			end
		end
	end

	local tower = getTower()

	if tower then
		local isValid, invalidCause = Level.LevelInstance:matches(tower)

		if isValid then
			self:bootstrapTower(tower :: Level.LevelInstance)
			return
		end

		self.log:error("Got invalid tower", tower:GetFullName(), "because:", invalidCause:formatErr())
		return
	end

	self.log:error(NO_TOWER_ERROR)
end

return prvd(KitServerProvider)
