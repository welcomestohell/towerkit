const logger = require "@core/shared/logger"
const AttributeOrder = require "@libs/attributes/AttributeOrder"
const observeAttributes = require "@libs/attributes/observeAttributes"
const tables = require "@libs/collections/tables"
const resolveInstance = require "@libs/core/resolveInstance"
const gt = require "@libs/vendor/gt"
const threadpool = require "@libs/threadpool"

const Attribute = {}
Attribute.__index = Attribute

export type Attribute<T> = setmetatable<{
	attribute: string,
	check: gt.Type,
	defaultValue: T,

	_observerCallbacks: { [Instance]: (string) -> () },
	_observerDisconnectors: { [Instance]: () -> () },
	_cache: { [Instance]: T },
	_updated: { [Instance]: true },
	_changeListeners: { [Instance]: { (value: T, attribute: Attribute<T>) -> () } },
	_fetchListeners: { [Instance]: { (value: T, attribute: Attribute<T>) -> () } },
}, typeof(Attribute)>

local function observeInstance(self: Attribute<unknown>, instance: Instance)
	if self._observerDisconnectors[instance] then return end

	if not self._observerCallbacks[instance] then
		local function onAttributesChanged(attribute)
			if attribute ~= self.attribute then return end

			local changeListeners = self._changeListeners[instance]
			if changeListeners and next(changeListeners) ~= nil then
				local value = instance:GetAttribute(self.attribute)
				self._cache[instance] = value
				self._updated[instance] = true
				threadpool.spawnCallbacks(changeListeners, value, self)
			else
				local disconnect: () -> () = self._observerDisconnectors[instance]
				if disconnect then disconnect() end
				self._observerDisconnectors[instance] = nil
				self._updated[instance] = nil
			end
		end

		self._observerCallbacks[instance] = onAttributesChanged
	end

	self._observerDisconnectors[instance] = observeAttributes(instance, self._observerCallbacks[instance])
end

local function fetchInstance(self: Attribute<unknown>, instance: Instance)
	local attribute = self.attribute
	local value = instance:GetAttribute(attribute)

	local isMissing = value == nil

	if self.check then
		local isValid, invalidCause = self.check:matches(value)

		if not isValid then
			if value ~= nil then
				logger:Warn(
					"Instance",
					instance,
					"has invalid value set for attribute named",
					string.format("%q", self.attribute) .. ": ",
					invalidCause
				)
			end

			value = self.defaultValue
			isMissing = true
		end
	end

	if isMissing and value ~= nil then instance:SetAttribute(attribute, value) end

	self._cache[instance] = value
	self._updated[instance] = true

	observeInstance(self, instance)

	local listeners = self._fetchListeners[instance]
	if listeners and next(listeners) ~= nil then
		for l in listeners do
			threadpool.spawn(l, value, self)
		end
	end

	return value
end

local function observeListener<T>(
	self: Attribute<T>,
	instance: unknown,
	listenerMap: { [Instance]: { (value: T, attribute: Attribute<T>) -> () } },
	listener: (value: T, attribute: Attribute<T>) -> ()
): () -> ()
	local resolved = resolveInstance(instance)

	local instanceListeners = listenerMap[resolved]
	if not instanceListeners then
		instanceListeners = tables.weak "k"
		listenerMap[resolved] = instanceListeners
	end
	table.insert(instanceListeners :: { (value: T, attribute: Attribute<T>) -> () }, listener)

	observeInstance(self, resolved)

	local disconnected = false
	local function disconnect()
		if disconnected then return end

		disconnected = true

		local listeners = listenerMap[resolved]
		if not listeners then return end

		tables.findAndRemove(listeners, listener)

		if next(listeners) == nil then listenerMap[resolved] = nil end
	end

	return disconnect
end

function Attribute.new<T>(attribute: string, check: T, defaultValue: T): Attribute<T>
	return AttributeOrder.track(setmetatable({
		attribute = attribute,
		check = gt.build(check) :: T,
		defaultValue = defaultValue,

		_observerCallbacks = tables.weak "k",
		_observerDisconnectors = tables.weak "k",
		_cache = tables.weak "k",
		_updated = tables.weak "k",
		_changeListeners = tables.weak "k",
		_fetchListeners = tables.weak "k",
	}, Attribute))
end

function Attribute.type<T>(_: Attribute<T>): T
	error "This function is undefined, and should only be used in type definitions: `typeof(attribute:type())`"
end

function Attribute.isAttribute(x: unknown)
	return type(x) == "table" and getmetatable(x) == Attribute
end

function Attribute.peek<T>(self: Attribute<T>, instance: resolveInstance.InstanceLike): T
	local value = self._cache[resolveInstance(instance)] :: any

	if value == nil then value = self.defaultValue end

	return value
end

function Attribute.fetch<T>(self: Attribute<T>, instance: resolveInstance.InstanceLike): T
	local fetched = fetchInstance(self, resolveInstance(instance))

	if fetched == nil then fetched = self.defaultValue end

	return fetched
end

function Attribute.get<T>(self: Attribute<T>, instance: resolveInstance.InstanceLike): T
	local resolved = resolveInstance(instance)

	if not self._updated[resolved] then return fetchInstance(self, resolved) end

	local cached = self._cache[resolved]

	if cached == nil then return self.defaultValue end

	return cached
end

function Attribute.getOrSet<T>(self: Attribute<T>, instance: resolveInstance.InstanceLike, default: T): T
	local value = self:get(instance)

	if default == nil then default = self.defaultValue end

	if value == nil then value = self:set(instance, default) end

	return value
end

function Attribute.getOrSetWith<T>(self: Attribute<T>, instance: resolveInstance.InstanceLike, derive: () -> T): T
	local value = self:get(instance)

	if value == nil then value = self:set(instance, derive()) end

	return value
end

function Attribute.set<T>(self: Attribute<T>, instance: resolveInstance.InstanceLike, value: T): T
	if value == nil then value = self.defaultValue end

	local resolved = resolveInstance(instance)

	resolved:SetAttribute(self.attribute, value)

	self._cache[resolved] = value
	self._updated[resolved] = true

	return value
end

function Attribute.assert<T>(self: Attribute<T?>, instance: resolveInstance.InstanceLike, message: string?): T
	local value = Attribute.get(self :: any, instance)
	assert(
		value ~= nil,
		message or `Instance {resolveInstance(instance):GetFullName()} is missing attribute {self.attribute}!`
	)
	return value
end

-- (lazily evaluated)
function Attribute.onFetch<T>(
	self: Attribute<T>,
	instance: resolveInstance.InstanceLike,
	listener: (value: T, attribute: Attribute<T>) -> ()
): () -> ()
	return observeListener(self, instance, self._fetchListeners, listener)
end

-- (eagerly evaluated)
function Attribute.onChange<T>(
	self: Attribute<T>,
	instance: resolveInstance.InstanceLike,
	listener: (value: T, attribute: Attribute<T>) -> ()
): () -> ()
	return observeListener(self, instance, self._changeListeners, listener)
end

function Attribute.onBind<T>(
	self: Attribute<T>,
	instance: resolveInstance.InstanceLike,
	listener: (value: T, attribute: Attribute<T>) -> ()
): () -> ()
	threadpool.spawn(listener, Attribute.get(self :: any, instance), self)
	return Attribute.onChange(self :: any, instance, listener)
end

function Attribute.awaitChange<T>(self: Attribute<T>, instance: resolveInstance.InstanceLike): T
	local currentThread = coroutine.running()
	observeListener(self, instance, self._changeListeners, function(value: T)
		task.spawn(currentThread, value)
	end)
	return coroutine.yield()
end

function Attribute.__call<T>(self: Attribute<T>, instance: resolveInstance.InstanceLike, ...: T): T
	return if select("#", ...) == 0 then self:get(instance) else self:set(instance, ...)
end

function Attribute.__tostring<T>(self: Attribute<T>)
	return `Attribute<{self.check:format()}>("{self.attribute}")`
end

return Attribute
