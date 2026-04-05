local tables = require("@libs/collections/tables")

local observersByInstance: { [Instance]: AttributeObserver } = tables.weak("k")

local AttributeObserver = {}
AttributeObserver.__index = AttributeObserver

export type AttributeObserver = setmetatable<{

	_instance: Instance,
	_connections: { [string]: RBXScriptConnection },
	_signals: { [string]: RBXScriptSignal },
}, typeof(AttributeObserver)>

function AttributeObserver.fromInstance(instance: Instance)
	local existing = observersByInstance[instance]
	if existing then
		return existing
	end

	local self = setmetatable({}, AttributeObserver)

	observersByInstance[instance] = self
	return self
end

return AttributeObserver
