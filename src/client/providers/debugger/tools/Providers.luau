local Life = require("@libs/memory/Life")

local Providers = {}
Providers.__index = Providers
Providers.title = "Providers"

export type Providers = setmetatable<{ life: Life.Life }, typeof(Providers)>

function Providers.new(life: Life.Life)
	return setmetatable({ life = life }, Providers)
end

function Providers.renderViewport() end

function Providers.renderWindow() end

return Providers
