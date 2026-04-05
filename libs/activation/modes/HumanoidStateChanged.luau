local character = require("@libs/character")
local types = require("../types")

local HumanoidStateChanged = {} :: types.ActivationMode

function HumanoidStateChanged.implement(context: types.ActivationContext)
	local humanoid = character.getHumanoid()
	context.activationLife:add(
		humanoid.StateChanged:Connect(function(old: Enum.HumanoidStateType, new: Enum.HumanoidStateType)
			if new == context.attributes.HumanoidStateType(context.instanceConfiguration) then
				context:onActivate { kind = "HumanoidStateChanged", old = old, new = new }
			end
		end)
	)
end

return HumanoidStateChanged
