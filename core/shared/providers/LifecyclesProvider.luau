local Players = game:GetService "Players"
local RunService = game:GetService "RunService"

local prvd = require "@roblox_packages/prvd"

local LifecyclesProvider = {}
export type LifecyclesProvider = typeof(LifecyclesProvider)
LifecyclesProvider.priority = -math.huge

LifecyclesProvider.preSimulation = prvd.lifecycle("onPreSimulation", prvd.fireConcurrent) :: prvd.Lifecycle<number>
LifecyclesProvider.postSimulation = prvd.lifecycle("onPostSimulation", prvd.fireConcurrent) :: prvd.Lifecycle<number>
LifecyclesProvider.preAnimation = prvd.lifecycle("onPreAnimation", prvd.fireConcurrent) :: prvd.Lifecycle<number>
LifecyclesProvider.preRender = prvd.lifecycle("onPreRender", prvd.fireConcurrent) :: prvd.Lifecycle<number>
LifecyclesProvider.playerAdded = prvd.lifecycle("onPlayerAdded", prvd.fireConcurrent) :: prvd.Lifecycle<Player>
LifecyclesProvider.playerRemoving = prvd.lifecycle("onPlayerRemoving", prvd.fireConcurrent) :: prvd.Lifecycle<Player>
LifecyclesProvider.characterAdded = prvd.lifecycle("onCharacterAdded", prvd.fireConcurrent) :: prvd.Lifecycle<Model>
LifecyclesProvider.characterRemoving =
	prvd.lifecycle("onCharacterRemoving", prvd.fireConcurrent) :: prvd.Lifecycle<Model>
LifecyclesProvider.localCharacterAdded =
	prvd.lifecycle("onLocalCharacterAdded", prvd.fireConcurrent) :: prvd.Lifecycle<Model>
LifecyclesProvider.localCharacterRemoving =
	prvd.lifecycle("onLocalCharacterRemoving", prvd.fireConcurrent) :: prvd.Lifecycle<Model>

local function wrapLifecycle(lifecycle: prvd.Lifecycle<...unknown>)
	return function(...: unknown)
		lifecycle:fire(...)
	end
end

function LifecyclesProvider.onInit(self: RbxLifecycles)
	self.connections = {} :: { RBXScriptConnection }

	self:_addConnections(
		RunService.PreSimulation:Connect(wrapLifecycle(LifecyclesProvider.preSimulation :: any)),
		RunService.PostSimulation:Connect(wrapLifecycle(LifecyclesProvider.postSimulation :: any)),
		RunService.PreAnimation:Connect(wrapLifecycle(LifecyclesProvider.preAnimation :: any))
	)

	if RunService:IsClient() then
		self:_addConnections(RunService.PreRender:Connect(wrapLifecycle(LifecyclesProvider.preRender :: any)))
	end

	local function onPlayerAdded(player: Player)
		self.playerAdded:fire(player)

		local character = player.Character or player.CharacterAdded:Wait()
		self.characterAdded:fire(character)

		if player == Players.LocalPlayer then self.localCharacterAdded:fire(character) end
	end

	for _, existingPlayer in Players:GetPlayers() do
		task.spawn(onPlayerAdded, existingPlayer)
	end

	self:_addConnections(
		Players.PlayerAdded:Connect(onPlayerAdded),
		Players.PlayerRemoving:Connect(wrapLifecycle(LifecyclesProvider.playerRemoving :: any))
	)
end

function LifecyclesProvider.finish(self: RbxLifecycles)
	for _, connection in self.connections do
		if connection.Connected then connection:Disconnect() end
	end
	table.clear(self.connections)
end

function LifecyclesProvider._addConnections(self: RbxLifecycles, ...: RBXScriptConnection)
	for index = 1, select("#", ...) do
		table.insert(self.connections, select(index, ...) :: RBXScriptConnection)
	end
end

export type RbxLifecycles = typeof(LifecyclesProvider)
return prvd(LifecyclesProvider)
