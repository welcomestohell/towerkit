local Result = require("@libs/Result")
local createChildOfClass = require("@self/createChildOfClass")
local functions = require("@libs/functions")
local gt = require("@libs/gt")
local log = require("@self/log")
local types = require("@self/types")
local useAttributes = require("@self/useAttributes")
local useChildOfClass = require("@self/useChildOfClass")

export type ActivationAttributes = types.ActivationAttributes
export type PredicateContext = types.PredicateContext
export type BindContext = types.BindContext
export type ActivationContext = types.ActivationContext
export type ActivationEvent = types.ActivationEvent
export type ActivationMode = types.ActivationMode

local modes: { [string]: ActivationMode } = {
	Click = require("@self/modes/Click"),
	Died = require("@self/modes/Died"),
	HumanoidStateChanged = require("@self/modes/HumanoidStateChanged"),
	Jumped = require("@self/modes/Jumped"),
	Prompt = require("@self/modes/Prompt"),
	Touch = require("@self/modes/Touch"),
}

export type RegisterModeError = { id: "invalidMode", cause: gt.Cause } | { id: "alreadyExists" }

local function registerMode(
	key: string,
	mode: types.ActivationMode
): Result.Result<types.ActivationMode, RegisterModeError>
	if modes[key] then
		return Result.Err({ id = functions.literal "alreadyExists" })
	end

	local isValid, invalidatedCause = types.ActivationMode:matches(mode)

	if isValid then
		modes[key] = mode
		return Result.Ok(mode)
	end

	return Result.Err({
		id = functions.literal "invalidMode",
		cause = invalidatedCause,
	})
end

local function unregisterMode(key: string)
	modes[key] = nil
end

export type ActivationError = { id: "noMode" } | { id: "unknownMode" } | { id: "predicateFailed", error: string }

local function activate(context: types.ActivationContext): Result.Result<nil, ActivationError>
	local modeKey = context.attributes.Mode(context.instanceConfiguration)
	if modeKey then
		local mode: ActivationMode? = modes[modeKey]

		if mode then
			if mode.predicate then
				local predicateResult = mode.predicate(context)
				if predicateResult:isErr() then
					return Result.Err({
						id = functions.literal "predicateFailed",
						error = predicateResult:unwrapErr() :: string,
					})
				end
			end

			mode.implement(context)
			return Result.Ok(nil)
		end

		return Result.Err({ id = functions.literal "unknownMode" })
	end
	return Result.Err({ id = functions.literal "noMode" })
end

local function bindActivation(bindContext: BindContext)
	local context = table.clone(bindContext) :: ActivationContext
	local life = context.instanceLife:extend()
	context.activationLife = life:extend()

	local function update()
		context.activationLife:destroy()
		context.activationLife = life:extend()

		if context.attributes.Enabled(context.instanceConfiguration) then
			local result = activate(context)
			if result:isErr() then
				log:warn(
					"Failed to bind activation for",
					context.instance:GetFullName(),
					"because:",
					result:unwrapErr()
				)
			end
		end
	end

	life:add(context.attributes.Enabled:onBind(context.instanceConfiguration, update))
	life:add(context.attributes.Mode:onBind(context.instanceConfiguration, update))
end

return table.freeze {
	modes = modes,
	registerMode = registerMode,
	unregisterMode = unregisterMode,

	activate = activate,
	bindActivation = bindActivation,

	createChildOfClass = createChildOfClass,
	useChildOfClass = useChildOfClass,
	useAttributes = useAttributes,
}
