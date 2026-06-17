local types = require "@core/shared/assets/types"

local function flattenAssetIds(assets: types.Assets): { string }
	local ids = {}
	for _, asset in assets do
		if type(asset) == "string" then
			table.insert(ids, asset)
		else
			local childIds = flattenAssetIds(asset)
			table.move(childIds, 1, #childIds, #ids + 1, ids)
		end
	end
	return ids
end

return flattenAssetIds
