-- Phenomenal name
export type MapMap<K, V, T> = { [K]: { [V]: T } }

local function get<K, V, T>(mmap: MapMap<K, V, T>, key: K): { [V]: T }
	local result = mmap[key]
	if result then return result end
	result = {}
	mmap[key] = result
	return result
end

local function set<K, V, T>(mmap: MapMap<K, V, T>, key: K, value: V, value2: T)
	get(mmap, key)[value] = value2
end

return table.freeze {
	get = get,
	set = set,
}
