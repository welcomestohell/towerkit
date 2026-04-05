local Iris = require("@libs/Iris")
local Level = require("@libs/Level")
local Life = require("@libs/memory/Life")

local Levels = {}
Levels.__index = Levels
Levels.title = "Levels"

export type Levels = setmetatable<{ life: Life.Life }, typeof(Levels)>

function Levels.new(life: Life.Life)
	return setmetatable({ life = life }, Levels)
end

function Levels.renderViewport() end

function Levels.renderWindow()
	Iris.TabBar()
	for _, level in Level.activeLevels do
		if Iris.Tab({ level.name }).state.isOpened.value then
			for _, tag in level.scripts.mechanicTags do
				local implementation = level.scripts.mechanicImplementationByTag[tag]
				Iris.Tree({ `{implementation.debuggerEmoji} {tag}` })
				Iris.End()
			end
		end
		Iris.End()
	end
	Iris.End()
end

return Levels
