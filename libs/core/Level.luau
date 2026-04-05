local Level = {}
Level.__index = Level

export type Level = setmetatable<{}, typeof(Level)>

function Level.new()
	return setmetatable({}, Level)
end

return table.freeze(Level)
