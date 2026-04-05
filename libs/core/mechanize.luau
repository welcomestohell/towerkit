local HttpService = game:GetService("HttpService")

local Life = require("@libs/memory/Life")
local Log = require("@libs/Log")
local Mechanic = require("@libs/Mechanic")
local MechanicImplementation = require("@libs/core/MechanicImplementation")
local Result = require("@libs/Result")
local gt = require("@libs/gt")

--[=[
	@function mechanize
	@tag Library
	@since 0.1.0

	Constructs a new Mechanic of an Instance from a MechanicImplementation.

	@param implementation Self -- The MechanicImplementation to use.
	@param outerLife Life.Life -- The outermost Life to be extended for the Mechanic.
	@param instance Instance -- The Instance to create a Mechanic for.
	@return Result<Mechanic<Self>, string> -- A Result with the created Mechanic if successful, or otherwise an error message.
]=]
local function mechanize<Self>(
	implementation: Self,
	outerLife: Life.Life,
	instance: Instance
): Result.Result<MechanicImplementation.Mechanic<Self>, string>
	local implementation = MechanicImplementation.downcast(implementation)

	local instanceConfiguration = instance
	if instance.ClassName == "Configuration" and instance.Parent then
		instanceConfiguration, instance = instance, instance.Parent
	end

	if implementation.instanceType then
		local instanceType = gt.build(implementation.instanceType)
		local isValid, reason = instanceType:matches(instance)
		if not isValid then
			return Result.Err(`Invalid instance type: {reason:formatErr()}`)
		end
	end

	local mechanicLife = outerLife:extend()
	mechanicLife:add(instance)
	mechanicLife:destroyOn(instance.Destroying)

	local mechanic: any = setmetatable({
		life = mechanicLife,
		id = HttpService:GenerateGUID(false),
		implementation = implementation,
		instance = instance,
		instanceConfiguration = instanceConfiguration,
	}, Mechanic._proxies[implementation])
	mechanic.log = Log.new(mechanic)

	return Result.Ok(mechanic)
end

return mechanize
