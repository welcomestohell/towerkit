local tables = require("@libs/collections/tables")

export type MapArray<K, V> = { [K]: { V } }

local function get<K, V>(marray: MapArray<K, V>, key: K): { V }
	local result = marray[key]
	if result then
		return result
	end
	result = {}
	marray[key] = result
	return result
end

local function push<K, V>(marray: MapArray<K, V>, key: K, value: V)
	table.insert(get(marray, key), value)
end

local function pop<K, V>(marray: MapArray<K, V>, key: K, value: V)
	return table.remove(get(marray, key), value)
end

local function remove<K, V>(marray: MapArray<K, V>, key: K, value: V)
	tables.findAndRemove(get(marray, key), value)
end

return table.freeze {
	get = get,
	push = push,
	pop = pop,
	remove = remove,
}
