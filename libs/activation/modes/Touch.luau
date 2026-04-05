local Result = require("@libs/Result")
local touch = require("@libs/touch")
local types = require("../types")

local Touch = {} :: types.ActivationMode

function Touch.predicate(context: types.PredicateContext)
	if context.instance:IsA("BasePart") then
		return Result.Ok(nil)
	end
	return Result.Err(`Expected a BasePart, got {context.instance.ClassName}`)
end

function Touch.implement(context: types.ActivationContext)
	context.activationLife:add((context.instance :: BasePart).Touched:Connect(function(toucher: BasePart)
		if touch.isToucherValid(context.attributes.Touch, context.instance, context.instanceConfiguration, toucher) then
			context:onActivate { kind = "Touch", toucher = toucher }
		end
	end))
end

return Touch
