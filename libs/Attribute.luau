local Log = require("./Log")
local gt = require("@pkgs/gt")
local tables = require("@libs/collections/tables")
local threadpool = require("@libs/threadpool")

export type AttributeValue =
	| string
	| boolean
	| number
	| UDim
	| UDim2
	| BrickColor
	| Color3
	| Vector2
	| Vector3
	| CFrame
	| NumberSequence
	| ColorSequence
	| NumberRange
	| Rect
	| Font

-- LUAU FIXME: Can't require the Mechanic class due to cyclic dependencies, so
-- we specify a proxy type.
export type ResolvableInstance = unknown

local log = Log.new("Attribute")

local Attribute = {}
Attribute.__index = Attribute

export type Attribute<T> = setmetatable<{
	attribute: string,
	check: gt.Type?,
	defaultValue: T,
	_cache: { [Instance]: T },
	_signals: { [Instance]: RBXScriptSignal },
	_updated: { [Instance]: true },
	_observers: { [Instance]: RBXScriptConnection? },
	_observerCallbacks: { [Instance]: () -> ()? },
	_changeListeners: { [Instance]: { [(value: T, attribute: any) -> ()]: true } },
	_fetchListeners: { [Instance]: { [(value: T, attribute: any) -> ()]: true } },
}, typeof(Attribute)>

local function resolveInstance(self: Attribute<any>, resolvable: any): Instance
	local type = typeof(resolvable)
	if type == "Instance" then
		return resolvable
	elseif type == "table" then
		if not resolvable.instanceConfiguration and not resolvable.instance then
			print(resolvable)
		end
		return resolvable.instanceConfiguration or resolvable.instance
	else
		error(
			`Expected an instance or a mechanic to resolve {self.attribute}, got {resolvable} of type {typeof(
				resolvable
			)}`
		)
	end
end

local function observeChanges(self: Attribute<unknown>, attribute: string, instance: Instance)
	if not self._observers[instance] then
		local signal = self._signals[instance]
		if not signal then
			signal = instance:GetAttributeChangedSignal(attribute)
			self._signals[instance] = signal
		end

		local observe = self._observerCallbacks[instance]
		if not observe then
			function observe()
				local listeners = self._changeListeners[instance]
				if listeners and next(listeners) ~= nil then
					local value = instance:GetAttribute(self.attribute)
					for l in listeners do
						threadpool.spawn(l, value, self)
					end
				else
					local connection = self._observers[instance]
					if connection and connection.Connected then
						connection:Disconnect()
					end
					self._observers[instance] = nil
				end
				self._updated[instance] = nil
			end

			self._observerCallbacks[instance] = observe
		end

		self._observers[instance] = (signal :: RBXScriptSignal):Connect(observe :: () -> ())
	end
end

local function fetchAttribute(self: Attribute<unknown>, instance: Instance)
	local attribute = self.attribute
	local value: any = instance:GetAttribute(attribute)

	local isMissing = value == nil

	if self.check then
		local isValid, invalidCause = self.check:matches(value)

		if not isValid then
			if value ~= nil then
				log:warn(
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

	if isMissing and value ~= nil then
		instance:SetAttribute(attribute, value)
	end

	self._cache[instance] = value
	self._updated[instance] = true

	observeChanges(self, attribute, instance)

	local listeners = self._fetchListeners[instance]
	if listeners and next(listeners) ~= nil then
		for l in listeners do
			threadpool.spawn(l, value, self)
		end
	end

	return value
end

local function observeListener<T>(
	attribute: Attribute<T>,
	instance: ResolvableInstance,
	listenerMap: { [Instance]: { [(value: T, attribute: Attribute<T>) -> ()]: true } },
	listener: (value: T, attribute: Attribute<T>) -> ()
): () -> ()
	local resolved = resolveInstance(attribute, instance)

	local instanceListeners = listenerMap[resolved]
	if not instanceListeners then
		instanceListeners = tables.weak("k") :: any
		listenerMap[resolved] = instanceListeners
	end
	instanceListeners[listener] = true

	observeChanges(attribute, attribute.attribute, resolved)

	local disconnected = false
	local function disconnect()
		if disconnected then
			return
		end

		disconnected = true

		local listeners = listenerMap[resolved]

		if not listeners then
			return
		end

		listeners[listener] = nil

		if next(listeners) == nil then
			listenerMap[resolved] = nil
		end
	end

	return disconnect
end

local function new(attribute: any, check: any, defaultValue: any): Attribute<any>
	return setmetatable({
		attribute = attribute,
		check = check,
		defaultValue = defaultValue,
		_cache = tables.weak("k"),
		_signals = tables.weak("k"),
		_updated = tables.weak("k"),
		_observers = tables.weak("k"),
		_observerCallbacks = tables.weak("k"),
		_changeListeners = tables.weak("k"),
		_fetchListeners = tables.weak("k"),
	}, Attribute) :: any
end

Attribute.new = new :: (
	& (<T>(attribute: string, check: T, defaultValue: T) -> Attribute<T>)
	& (<T>(attribute: string, check: T) -> Attribute<T?>)
)

function Attribute.type<T>(_: Attribute<T>): T
	error("This function can only be used for type definitions, ie. `typeof(attribute:type())`")
end

function Attribute.isAttribute(x: any)
	return type(x) == "table" and getmetatable(x) == Attribute
end

function Attribute.peek<T>(self: Attribute<T>, instance: ResolvableInstance): T
	local value = self._cache[resolveInstance(self, instance)] :: any

	if value == nil then
		value = self.defaultValue
	end

	return value
end

function Attribute.fetch<T>(self: Attribute<T>, instance: ResolvableInstance): T
	local fetched = fetchAttribute(self, resolveInstance(self, instance))

	if fetched == nil then
		fetched = self.defaultValue
	end

	return fetched
end

function Attribute.get<T>(self: Attribute<T>, instance: ResolvableInstance): T
	local resolved = resolveInstance(self, instance)

	if not self._updated[resolved] then
		return fetchAttribute(self, resolved)
	end

	local cached = self._cache[resolved]

	if cached == nil then
		return self.defaultValue
	end

	return cached
end

function Attribute.getOrSet<T>(self: Attribute<T>, instance: ResolvableInstance, default: T): T
	local value = self:get(instance)

	if default == nil then
		default = self.defaultValue
	end

	if value == nil then
		value = self:set(instance, default)
	end

	return value
end

function Attribute.getOrSetWith<T>(self: Attribute<T>, instance: ResolvableInstance, derive: () -> T): T
	local value = self:get(instance)

	if value == nil then
		value = self:set(instance, derive())
	end

	return value
end

function Attribute.set<T>(self: Attribute<T>, instance: ResolvableInstance, value: T): T
	if value == nil then
		value = self.defaultValue
	end

	local resolved = resolveInstance(self, instance)

	resolved:SetAttribute(self.attribute, value)

	self._cache[resolved] = value
	self._updated[resolved] = true

	return value
end

function Attribute.assert<T>(self: Attribute<T?>, instance: ResolvableInstance, message: string?): T
	local value = Attribute.get(self :: any, instance)
	assert(
		value ~= nil,
		message or `Instance {resolveInstance(self, instance):GetFullName()} is missing attribute {self.attribute}!`
	)
	return value
end

-- (lazily evaluated)
function Attribute.onFetch<T>(
	self: Attribute<T>,
	instance: ResolvableInstance,
	listener: (value: T, attribute: Attribute<T>) -> ()
): () -> ()
	return observeListener(self, instance, self._fetchListeners, listener)
end

-- (eagerly evaluated)
function Attribute.onChange<T>(
	self: Attribute<T>,
	instance: ResolvableInstance,
	listener: (value: T, attribute: Attribute<T>) -> ()
): () -> ()
	return observeListener(self, instance, self._changeListeners, listener)
end

function Attribute.onBind<T>(
	self: Attribute<T>,
	instance: ResolvableInstance,
	listener: (value: T, attribute: Attribute<T>) -> ()
): () -> ()
	threadpool.spawn(listener, Attribute.get(self :: any, instance), self)
	return Attribute.onChange(self :: any, instance, listener)
end

function Attribute.__call<T>(self: Attribute<T>, instance: ResolvableInstance, ...: T): T
	return if select("#", ...) == 0 then self:get(instance) else self:set(instance, ...)
end

function Attribute.__tostring<T>(self: Attribute<T>)
	return if self.check
		then `Attribute<{self.check:format()}>("{self.attribute}")`
		else `Attribute("{self.attribute}")`
end

return Attribute
