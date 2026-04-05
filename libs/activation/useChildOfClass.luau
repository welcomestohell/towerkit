local createChildOfClass = require("./createChildOfClass")
local log = require("./log")
local roblox = require("@shared/generated/types/roblox")
local types = require("./types")

local function useChildOfClass<ClassName>(
	context: types.ActivationContext,
	childName: string,
	childClass: ClassName | keyof<roblox.Instances>
): index<roblox.Instances, ClassName>
	local child = context.instance:FindFirstChild(childName)

	if child then
		if child:IsA(childClass) then
			return child :: any
		end

		log:warn(`\
			While binding activation, expected child "{childName}" of {context.instance:GetFullName()} to be a \
			{childClass}, but got {child.Name}.\
		`)

		child.Name ..= " (INVALID)"
	end

	-- LUAU: too complex and volatile
	return (createChildOfClass :: any)(context, childName, childClass)
end

return useChildOfClass
