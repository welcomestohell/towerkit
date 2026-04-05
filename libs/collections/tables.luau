export type function Partial(ty: type)
	assert(ty:is("table"), "expected table")

	ty = types.copy(ty)

	for key, values in ty:properties() do
		if values.read then
			if values.read == values.write then
				ty:setproperty(key, types.optional(values.read))
			else
				ty:setreadproperty(key, types.optional(values.read))
			end
		elseif values.write then
			ty:setwriteproperty(key, types.optional(values.write))
		end
	end

	return ty
end

export type function Readonly(ty: type)
	assert(ty:is("table"), "expected table")

	ty = types.copy(ty)

	for key, values in ty:properties() do
		ty:setwriteproperty(key, nil)
	end

	return ty
end

export type function Writeonly(ty: type)
	assert(ty:is("table"), "expected table")

	ty = types.copy(ty)

	for key, values in ty:properties() do
		ty:setreadproperty(key, nil)
	end

	return ty
end

export type function Omit(ty: type, key: type)
	ty = types.copy(ty)
	ty:setproperty(key, nil)
	return ty
end

export type function With(ty: type, key: type, value: type)
	ty = types.copy(ty)
	ty:setproperty(key, value)
	return ty
end

export type function Merge(lhs: type, rhs: type)
	local result = types.newtable()

	for _, tbl in { lhs, rhs } do
		for key, values in tbl:properties() do
			if values.read then
				result:setreadproperty(key, values.read)
			end

			if values.write then
				result:setwriteproperty(key, values.write)
			end
		end
	end

	return result
end

local WEAK_METATABLES = {
	k = table.freeze { __mode = "k" },
	v = table.freeze { __mode = "v" },
	kv = table.freeze { __mode = "kv" },
}

local function map<KI, VI, KO, VO>(input: { [KI]: VO }, transform: (KI, VI, { [KI]: VI }) -> (KO, VO))
	local result = table.create(#input) :: any

	for inputKey, inputValue in input do
		local outputKey, outputValue = transform(inputKey, inputValue, input)
		result[outputKey] = outputValue
	end

	return result
end

local function filter<KI, VI, KO, VO>(input: { [KI]: VO }, predicate: (KI, VI, { [KI]: VI }) -> boolean)
	local result = {}

	for key, value in input do
		if predicate(key, value, input) then
			result[key] = value
		end
	end

	return result
end

local function filterMap<KI, VI, KO, VO>(
	input: { [KI]: VO },
	predicate: (KI, VI, { [KI]: VI }) -> boolean,
	transform: (KI, VI, { [KI]: VI }) -> (KO, VO)
)
	local result = {}

	for inputKey, inputValue in input do
		if predicate(inputKey, inputValue, input) then
			local outputKey, outputValue = transform(inputKey, inputValue, input)
			result[outputKey] = outputValue
		end
	end

	return result
end

local function keys<K>(target: { [K]: any }): { K }
	local result = {}
	for key in target do
		table.insert(result, key)
	end
	return result
end

local function values<V>(target: { [any]: V }): { V }
	local result = {}
	for _, value in target do
		table.insert(result, value)
	end
	return result
end

local function weak(mode: keyof<typeof(WEAK_METATABLES)>): { [any]: any }
	return setmetatable({}, WEAK_METATABLES[mode]) :: any
end

local function deepCopy<T>(target: T & {})
	local clone = table.clone(target)
	for key, value in clone :: { [any]: any } do
		if type(value) == "table" then
			clone[key] = deepCopy(value)
		end
	end
	return clone
end

local function findAndRemove<T>(haystack: { T }, needle: T)
	local index = table.find(haystack, needle)
	if index then
		table.remove(haystack, index)
	end
end

return table.freeze {
	map = map,
	filter = filter,
	filterMap = filterMap,
	keys = keys,
	values = values,
	weak = weak,
	deepCopy = deepCopy,
	findAndRemove = findAndRemove,

	create = table.create :: ((count: number) -> { any }) & (<V>(count: number, value: V) -> { V }),
}
