local collectAssets = require "@core/shared/assets/collectAssets"
local flattenAssetIds = require "@core/shared/assets/flattenAssetIds"

local function flattenAssetModules(assetIds: { string }?): { string }
	assetIds = assetIds or {}
	local assetModules = collectAssets()
	for _, assets in assetModules do
		local ids = flattenAssetIds(assets)
		table.move(ids, 1, #ids, #assetIds + 1, assetIds)
	end
	return assetIds
end

return flattenAssetModules
