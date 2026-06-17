const types = require "@core/shared/assets/types"

local function flattenAssetPaths(modules: { [string]: types.Assets }, current: { string }?): { [string]: string }
	current = current or {}
	const paths = {}
	for key, asset in modules do
		const current = table.clone(current)
		table.insert(current, key)
		if type(asset) == "string" then
			paths[table.concat(current, "/")] = asset
		else
			for subpath, subasset in flattenAssetPaths(asset :: { [string]: types.Assets }, current) do
				paths[subpath] = subasset
			end
		end
	end
	return paths
end

return flattenAssetPaths
