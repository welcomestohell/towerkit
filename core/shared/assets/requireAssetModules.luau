local ReplicatedStorage = game:GetService "ReplicatedStorage"

local types = require "@core/shared/assets/types"

const function requireAssetModules(): { [string]: types.Assets }
	const result = {}
	for _, module in ReplicatedStorage:WaitForChild("Internal"):WaitForChild("Assets"):GetChildren() do
		if module:IsA "ModuleScript" then result[module.Name] = (require)(module) end
	end
	return result
end

return requireAssetModules
