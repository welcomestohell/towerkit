export type MapSet<K, V> = { [K]: { [V]: true } }

local function get<K, V>(mset: MapSet<K, V>, key: K): { [V]: true }
	local result = mset[key]
	if result then return result end
	result = {}
	mset[key] = result
	return result
end

local function set<K, V>(mset: MapSet<K, V>, key: K, value: V)
	get(mset, key)[value] = true
end

local function remove<K, V>(mset: MapSet<K, V>, key: K, value: V)
	get(mset, key)[value] = nil
end

return table.freeze {
	get = get,
	set = set,
	remove = remove,
}
