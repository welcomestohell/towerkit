const types = require "@libs/types"

const function map<K, VI, VO>(object: { [K]: VI }, fn: (types.NonNilable<VI>, K) -> VO): { [K]: types.NonNilable<VO> }
	local result: { [K]: VO } = {}
	for key, value in object do
		result[key] = fn(value, key)
	end
	return result
end

const function filter<K, V>(object: { [K]: V }, predicate: (types.NonNilable<V>, K) -> boolean): { [K]: V }
	local result: { [K]: V } = {}
	for key, value in object do
		if predicate(value, key) then result[key] = value end
	end
	return result
end

const function keys<K>(object: { [K]: any }): { K }
	local result: { K } = {}
	for key in object do
		table.insert(result, key)
	end
	return result
end

const function set<T, K>(object: T & {}, key: K & keyof<T>, value: index<T, K>): T
	if object[key] ~= value then
		object = table.clone(object)
		object[key] = value
	end
	return object
end

const function delete<T>(object: T & {}, key: keyof<T>): T
	if object[key] ~= nil then
		object = table.clone(object)
		object[key] = nil
	end
	return object
end

const function update<T, K>(object: T & {}, key: K & keyof<T>, fn: (types.NonNilable<index<T, K>>) -> index<T, K>?): T
	local value: unknown = object[key]
	if value ~= nil then
		local newValue = fn(value :: K)
		if newValue ~= value then
			object = table.clone(object)
			object[key] = newValue
		end
	end
	return object
end

const function join<T>(object: T & {}, source: types.Partial<T>?): T
	if source == nil then return object end
	local result = object
	for key, value in source :: { [any]: any } do
		if result[key] ~= value then
			if result == object then result = table.clone(object) :: never end
			result[key] = value
		end
	end
	return result
end

return table.freeze {
	map = map,
	filter = filter,
	keys = keys,
	set = set,
	delete = delete,
	update = update,
	join = join,
}
