local ReplicatedStorage = game:GetService "ReplicatedStorage"

local types = require "@core/shared/assets/types"

local function collectAssets(): { types.Assets }
	local assets = {}
	for _, module in ReplicatedStorage:WaitForChild("Internal"):WaitForChild("Assets"):GetChildren() do
		assert(module:IsA "ModuleScript", `Unexpected instance {module.Name} in asphalt assets`)
		table.insert(assets, (require)(module) :: types.Assets)
	end
	return assets
end

return collectAssets
