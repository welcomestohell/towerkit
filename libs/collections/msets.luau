export type MapSet<K, V> = { [K]: { [V]: true } }

local function get<K, V>(mset: MapSet<K, V>, key: K): { [V]: true }
	local result = mset[key]
	if result then
		return result
	end
	result = {}
	mset[key] = result
	return result
end

return table.freeze {
	get = get,
}
