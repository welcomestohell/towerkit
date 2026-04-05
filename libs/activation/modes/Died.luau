local character = require("@libs/character")
local types = require("../types")

local HumanoidStateChange = {} :: types.ActivationMode

function HumanoidStateChange.implement(context: types.ActivationContext)
	local humanoid = character.getHumanoid()
	context.activationLife:add(humanoid.Died:Connect(function()
		context:onActivate { kind = "Died" }
	end))
end

return HumanoidStateChange
