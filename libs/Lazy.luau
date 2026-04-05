local Promise = require("@pkgs/Promise")

local Lazy = {}
Lazy.__index = Lazy
Lazy.type = "Lazy"

export type Lazy<T> = setmetatable<{ loaded: boolean, loadCallback: () -> T, value: T? }, typeof(Lazy)>

function Lazy.new<T>(loadCallback: () -> T): Lazy<T>
	return setmetatable({ loaded = false, loadCallback = loadCallback, value = nil }, Lazy)
end

function Lazy.isLazy(x: any)
	return typeof(x) == "table" and getmetatable(x) == Lazy
end

function Lazy.get<T>(self: Lazy<T>): T
	if self.loaded then
		return self.value :: T
	end

	local value = self.loadCallback()
	self.value = value
	self.loaded = true

	return value
end

Lazy.getAsync = Promise.promisify(Lazy.get) :: <T>(self: Lazy<T>) -> Promise.TypedPromise<T>

return table.freeze(Lazy)
