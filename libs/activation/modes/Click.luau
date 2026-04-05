local Players = game:GetService("Players")

local types = require("../types")
local useChildOfClass = require("../useChildOfClass")

local Click = {} :: types.ActivationMode

function Click.implement(context: types.ActivationContext)
	local detector = useChildOfClass(context, "ActivationClickDetector", "ClickDetector")
	context.activationLife:add(detector.MouseClick:Connect(function(player: Player)
		-- TODO: is this check needed?
		if player == Players.LocalPlayer then
			context:onActivate { kind = "Click", detector = detector }
		end
	end))
end

return Click
