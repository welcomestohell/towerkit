local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Level = require("@libs/Level")
local Life = require("@libs/memory/Life")
local Log = require("@libs/Log")
local audios = require("@shared/generated/audios")
local character = require("@libs/character")
local net = require("@client/generated/net")
local prvd = require("@shared/prvdmwrong/prvdmwrong")
local sounds = require("@libs/sounds")

local KitClientProvider = {}
export type KitClientProvider = typeof(KitClientProvider)
KitClientProvider.log = Log.new(KitClientProvider)

function KitClientProvider.constructor(self: KitClientProvider)
	self.life = Life.new()
	Level.baseScripts:tryInstances(ReplicatedStorage.Scripts.Core:GetDescendants())
end

function KitClientProvider.onStart(self: KitClientProvider)
	if not game:IsLoaded() then
		self.log:trace("Waiting for game to finish loading")
		game.Loaded:Wait()
	end

	sounds.useAssets(audios :: any)
	self.log:trace("Loaded audios from assets:", sounds.assetPaths)
	task.spawn(sounds.preloadAssets)

	local tower = net.getTower.invoke():expect()

	local existingMechanics = tower:FindFirstChild("Mechanic")
	if existingMechanics then
		self.log:trace("Removing existing mechanics")
		existingMechanics:Destroy()
	end

	local mechanics = net.loadMechanics.invoke():expect()
	mechanics:Clone().Parent = tower
	mechanics:Destroy()

	local levelResult = Level.new(self.life, tower.Name, tower)
	levelResult:match({
		Ok = function(level: Level.Level)
			self.log:trace("Starting kit...")
			character.getCharacter():PivotTo(level.instance.SpawnCharacter.CFrame)
			level:start()
			self.log:info("Kit has started!")
		end,
		Err = function(e)
			if e.id == "invalidInstance" then
				self.log:error("Invalid kit instance client-side:", e.cause:formatErr())
			end
			self.log:error("Unknown error while initializing kit:", e)
		end,
	} :: any)
end

function KitClientProvider.onFinish(self: KitClientProvider)
	self.log:trace("Cleaning up!")
	self.life:destroy()
end

return prvd(KitClientProvider)
