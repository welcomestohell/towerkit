local gt = require("@libs/gt")
local tables = require("@libs/collections/tables")

local AttributeMap = {}
AttributeMap.__index = AttributeMap

export type AttributeMap<T> = setmetatable<{
	pattern: string,
	expectedType: T,
	_instances: { [Instance]: { [string]: T } },

	_fetchListeners: { [(key: string, value: T, map: AttributeMap<T>) -> ()]: true },
	_changeListeners: { [(key: string, value: T, map: AttributeMap<T>) -> ()]: true },
}, typeof(AttributeMap)>

function AttributeMap.new<T>(pattern: string, expectedType: T): AttributeMap<T>
	return setmetatable({
		pattern = pattern,
		expectedType = gt.build(expectedType),
		_instances = tables.weak("k"),
	}, AttributeMap)
end

function AttributeMap.fromPrefix(prefix: string, expectedType: gt.Type)
	return AttributeMap.new(`^{prefix}_(%w+)`, expectedType)
end

function AttributeMap.peek<T>(self: AttributeMap<T>, instance: Instance) end

function AttributeMap.fetch<T>(self: AttributeMap<T>, instance: Instance) end

function AttributeMap.get<T>(self: AttributeMap<T>, instance: Instance): { [string]: T }
	return {}
end

function AttributeMap.index<T>(self: AttributeMap<T>, instance: Instance, key: string) end

function AttributeMap.getOrSet<T>(self: AttributeMap<T>, instance: Instance, key: string) end

function AttributeMap.clear<T>(self: AttributeMap<T>, instance: Instance) end

function AttributeMap.set<T>(self: AttributeMap<T>, key: string) end

function AttributeMap.onFetch<T>(self: AttributeMap<T>, listener: (key: string, map: { [string]: T }) -> ()) end

function AttributeMap.onChange<T>(self: AttributeMap<T>, listener: (key: string, map: { [string]: T }) -> ()) end

function AttributeMap.onBind<T>(self: AttributeMap<T>, listener: (key: string, map: { [string]: T }) -> ()) end

AttributeMap.__call = AttributeMap.get

return AttributeMap
