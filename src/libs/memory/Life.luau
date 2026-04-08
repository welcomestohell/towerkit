local destruction = require("./destruction")
local tables = require("@libs/collections/tables")
local threadpool = require("@libs/threadpool")

--[=[
	@class Life
	@tag Library

	Represents a lifespan. Throughout a Life, destroyable objects can be added
	to be later cleaned up in Last In, First Out order.
]=]
local Life = {}
Life.__index = Life

export type Life = setmetatable<{ destroyed: boolean, objects: { destruction.Destroyable } }, typeof(Life)>

function Life.new(): Life
	return setmetatable({
		destroyed = false,
		objects = {} :: { destruction.Destroyable },
	}, Life)
end

function Life.isLife(x: any): boolean
	return typeof(x) == "table" and getmetatable(x) == Life
end

function Life.add<T>(self: Life, bound: T): T
	if self.destroyed then
		return bound
	end
	table.insert(self.objects, bound)
	return bound
end

function Life.addMany<T...>(self: Life, ...: T...): T...
	if self.destroyed then
		return ...
	end
	for index = 1, select("#", ...) do
		table.insert(self.objects, select(index, ...) :: destruction.Destroyable)
	end
	return ...
end

function Life.extend(self: Life)
	local inner = Life.new()
	self:add(inner)
	inner:add(function()
		self:remove(inner)
	end)
	return inner
end

function Life.spawn<T>(self: Life, bound: (...any) -> ...any): thread?
	if self.destroyed then
		return nil
	end
	local thread = threadpool.spawn(bound)
	table.insert(self.objects, function()
		task.cancel(thread)
	end)
	return thread
end

function Life.delay<A...>(self: Life, duration: number, fn: (A...) -> (), ...: A...): thread?
	if self.destroyed then
		return nil
	end
	local thread = task.delay(duration, function(...)
		if self.destroyed == false then
			fn(...)
		end
	end, ...)
	return self:add(thread)
end

function Life.remove<T>(self: Life, bound: T): T
	if self.destroyed then
		return bound
	end
	tables.findAndRemove(self.objects, bound)
	return bound
end

function Life.removeMany<T...>(self: Life, ...: T...): T...
	if self.destroyed then
		return ...
	end
	for index = 1, select("#", ...) do
		tables.findAndRemove(self.objects, select(index, ...))
	end
	return ...
end

function Life.removeAll(self: Life)
	table.clear(self.objects)
end

function Life.destroyOn(self: Life, signal: RBXScriptSignal): RBXScriptConnection?
	return if self.destroyed
		then nil
		else self:add(signal:Connect(function()
			self:destroy()
		end))
end

function Life.destroy(self: Life)
	if self.destroyed == false then
		self.destroyed = true

		for index = #self.objects, 1, -1 do
			destruction.destroy(self.objects[index])
		end

		table.clear(self.objects)
	end
end

function Life.wrapDestroy(self: Life): () -> ()
	return function()
		self:destroy()
	end
end

function Life.__tostring(_: Life)
	return "Life"
end

function Life.__len(self: Life)
	return #self.objects
end

return table.freeze(Life)
