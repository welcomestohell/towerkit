local Life = require("@libs/memory/Life")

local Console = {}
Console.__index = Console
Console.title = "Console"

export type Console = setmetatable<{ life: Life.Life }, typeof(Console)>

function Console.new(life: Life.Life)
	return setmetatable({ life = life }, Console)
end

function Console.renderViewport() end

function Console.renderWindow() end

return Console
