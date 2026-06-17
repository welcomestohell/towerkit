_G.PRVDMWRONG_PROFILE_LIFECYCLES = false

local ReplicatedStorage = game:GetService "ReplicatedStorage"
local RunService = game:GetService "RunService"
local ServerScriptService = game:GetService "ServerScriptService"

local logger = require "@core/shared/logger"
local prvd = require "@roblox_packages/prvd"

prvd.onProviderUsed(function(_, provider)
	logger:Debug("Used provider", provider.name)
end)
prvd.onLifecycleUsed(function(_, lifecycle)
	logger:Debug("Used lifecycle", tostring(lifecycle))
end)

local root = prvd.root()
root.onInit:register(function()
	logger:Debug "Initializing"
end)
root.onStart:register(function()
	logger:Debug "Starting"
end)
root.onStop:register(function()
	logger:Debug "Stopping"
end)

local function useProvidersFromMembers(memberParent: Instance)
	for _, member in memberParent:GetChildren() do
		local providers = member:FindFirstChild "providers"
		if providers then root:useModules(providers:GetDescendants()) end
	end
end

local function bootstrapClient()
	assert(RunService:IsClient(), "Wrong bootstrapper used on client/server")

	local internal = ReplicatedStorage:WaitForChild "Internal"
	useProvidersFromMembers(internal:WaitForChild "Client")
	useProvidersFromMembers(internal:WaitForChild "Shared")

	local startedRoot = root:start()
	game.Close:Once(function()
		startedRoot:stop()
	end)
end

local function bootstrapServer()
	assert(RunService:IsServer(), "Wrong bootstrapper used on client/server")

	useProvidersFromMembers(ReplicatedStorage:WaitForChild("Internal"):WaitForChild "Shared")
	useProvidersFromMembers(ServerScriptService:WaitForChild("Internal"):WaitForChild "Server")

	local startedRoot = root:start()
	game:BindToClose(function()
		startedRoot:stop()
	end)
end

return table.freeze {
	root = root,
	useProvidersFromMembers = useProvidersFromMembers,
	bootstrapClient = bootstrapClient,
	bootstrapServer = bootstrapServer,
}
