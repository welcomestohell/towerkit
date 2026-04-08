local ReplicatedStorage = game:GetService("ReplicatedStorage")

local framework = require("@core/shared/framework")

framework.useModulesFromPath(ReplicatedStorage, "Internal", "Client", "providers")
framework.useModulesFromPath(ReplicatedStorage, "Internal", "Shared", "providers")
local root = framework.root:start()
game.Close:Once(function()
	root:finish()
end)
