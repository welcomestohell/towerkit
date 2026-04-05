local Life = require("@libs/memory/Life")

local About = {}
About.__index = About
About.title = "About"

export type About = setmetatable<{ life: Life.Life }, typeof(About)>

function About.new(life: Life.Life)
	return setmetatable({ life = life }, About)
end

function About.renderViewport() end

function About.renderWindow() end

return About
