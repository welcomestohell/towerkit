const ReplicatedStorage = game:GetService "ReplicatedStorage"

const LevelProvider = require "@core/client/providers/LevelProvider"
const Level = require "@libs/core/Level"
const logger = require "@core/shared/logger"
const net = require "@kit/client/generated/net"
const prvd = require "@roblox_packages/prvd"

const KitClientProvider = {}
export type KitClientProvider = typeof(KitClientProvider)

function KitClientProvider.onInit(self: KitClientProvider)
	Level.baseScripts
		:collectInstancesAsync(ReplicatedStorage:WaitForChild("TowerScripts"):WaitForChild("Kit"):GetDescendants())
		:await()
end

function KitClientProvider.onStart(self: KitClientProvider)
	const tower = net.getTower.invoke():expect()
	const existingMechanics = tower:FindFirstChild "Mechanics"
	if existingMechanics then
		logger:Debug "Removing existing mechanics"
		existingMechanics:Destroy()
	end

	const mechanics = net.loadMechanics.invoke():expect()
	mechanics:Clone().Parent = tower
	mechanics:Destroy()

	self.level = LevelProvider:tryLoadLevel(tower)
end

function KitClientProvider.onStop(self: KitClientProvider)
	if self.level then self.level.life:destroy() end
end

return prvd(KitClientProvider)
