local createChildOfClass = require "./createChildOfClass"
local logger = require "@core/shared/logger"
-- local roblox = require("@core/shared/generated/types/roblox")
local types = require "./types"

-- local function useChildOfClass<ClassName>(
-- 	context: types.ActivationContext,
-- 	childName: string,
-- 	childClass: ClassName | keyof<roblox.Instances>
-- ): index<roblox.Instances, ClassName>
local function useChildOfClass(context: types.ActivationContext, childName: string, childClass: string): any
	local child = context.instance:FindFirstChild(childName)

	if child then
		if child:IsA(childClass) then return child :: any end

		logger:Warn(`\
			While binding activation, expected child "{childName}" of {context.instance:GetFullName()} to be a \
			{childClass}, but got {child.Name}.\
		`)

		child.Name ..= " (INVALID)"
	end

	-- LUAU: too complex and volatile
	return (createChildOfClass :: any)(context, childName, childClass)
end

return useChildOfClass
