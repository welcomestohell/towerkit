local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local framework = require("@core/shared/framework")

framework.useModulesFromPath(ServerScriptService, "Internal", "Server", "providers")
framework.useModulesFromPath(ReplicatedStorage, "Internal", "Shared", "providers")
local root = framework.root:start()
game:BindToClose(function()
	root:finish()
end)
