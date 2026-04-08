local roblox = require("@core/shared/generated/types/roblox")
local types = require("./types")

local function createChildOfClass<ClassName>(
	context: types.ActivationContext,
	childName: string,
	childClass: ClassName | keyof<roblox.Instances>
): index<roblox.Instances, ClassName>
	local instance = context.activationLife:add(Instance.new(childClass))
	instance.Name = childName
	instance.Parent = context.instance
	return instance :: any
end

return createChildOfClass
