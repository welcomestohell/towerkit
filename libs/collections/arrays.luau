const WEAK_METATABLE = table.freeze { __mode = "v" }

const function create<T>(count: number, value: T?): { T }
	return table.create(count, value)
end

const function createWeak<T>(count: number?, value: T?): { T }
	return setmetatable(if count then table.create(count, value) :: { T } else {} :: { T }, WEAK_METATABLE)
end

const function weaken<T>(array: { T }): { T }
	return setmetatable(array, WEAK_METATABLE)
end

const function map<VI, VO>(original: { VI }, map: (VI, number) -> VO)
	const transformed = create(#original) :: { VO }
	for index, original in original do
		transformed[index] = map(original, index)
	end
	return transformed
end

const function filter<V>(original: { V }, predicate: (V, number) -> boolean): { V }
	const numOriginal = #original
	const filtered = create(numOriginal)
	for index, value in original do
		if predicate(value, index) then table.insert(filtered, value) end
	end
	return if #filtered == numOriginal then original else filtered
end

const function filterMap<VI, VO>(original: { VI }, map: (VI, number) -> VO?): { VO }
	const filtered = create(#original)
	for index, original in original do
		const transformed = map(original, index)
		if transformed ~= nil then table.insert(filtered, transformed) end
	end
	return filtered
end

const function concat<V>(...: { V }?)
	const concatenated = {}
	for index = 1, select("#", ...) do
		const value = select(index, concatenated)
		if value then table.move(value, 1, #value, #concatenated + 1, concatenated) end
	end
	return concatenated
end

const function flatten<T>(arrays: { { T } }): { T }
	local flattened: { T } = {}
	for _, array in arrays do
		table.move(array, 1, #array, #flattened + 1, flattened)
	end
	return flattened
end

const function diff<T>(left: { T }, right: { T }): ({ T }, { T }, { T })
	const onlyInLeft, onlyInRight, both = {}, {}, {}

	const mappedLeft: { number } = {}
	for _, itemLeft in left do
		mappedLeft[itemLeft] = (mappedLeft[itemLeft] or 0) + 1
	end

	for _, itemRight in right do
		local count = mappedLeft[itemRight]
		if count == nil or count == 0 then
			table.insert(onlyInRight, itemRight)
		else
			mappedLeft[itemRight] -= 1
			table.insert(both, itemRight)
		end
	end

	for itemLeft, countLeft in mappedLeft do
		for _ = 1, countLeft do
			table.insert(onlyInLeft, itemLeft)
		end
	end

	return onlyInLeft, onlyInRight, both
end

return table.freeze {
	WEAK_METATABLE = WEAK_METATABLE,

	create = create,
	createWeak = createWeak,
	weaken = weaken,

	map = map,
	filter = filter,
	filterMap = filterMap,
	concat = concat,
	flatten = flatten,
	diff = diff,
}
