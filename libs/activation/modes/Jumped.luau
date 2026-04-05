local UserInputService = game:GetService("UserInputService")

local types = require("../types")

local Jump = {} :: types.ActivationMode

function Jump.implement(context: types.ActivationContext)
	context.activationLife:add(UserInputService.JumpRequest:Connect(function()
		context:onActivate { kind = "Jumped" }
	end))
end

return Jump
