local Players = game:GetService("Players")

local types = require("../types")
local useChildOfClass = require("../useChildOfClass")

local Prompt = {} :: types.ActivationMode

function Prompt.implement(context: types.ActivationContext)
	local prompt = useChildOfClass(context, "ActivationProximityPrompt", "ProximityPrompt")
	context.activationLife:add(prompt.Triggered:Connect(function(player: Player)
		-- TODO: is this check needed?
		if player == Players.LocalPlayer then
			context:onActivate { kind = "Prompt", prompt = prompt }
		end
	end))
end

return Prompt
