local Workspace = game:GetService("Workspace")

local types = require("@self/types")
local useAttributes = require("@self/useAttributes")
local useSeamlessAttributes = require("@self/useSeamlessAttributes")

export type TeleporterAttributes = types.TeleporterAttributes
export type SeamlessAttributes = types.SeamlessAttributes
export type TeleportContext = types.TeleportContext
export type TransitionContext = types.TransitionContext
export type Transition = types.Transition

local transitions: { [string]: Transition } = {
	Instant = require("@self/transitions/Instant"),
	ScreenFade = require("@self/transitions/ScreenFade"),
	Tween = require("@self/transitions/Tween"),
}

local function calculateSeamless(context: TeleportContext)
	local targetPosition = context.target.Position
	local destinationPosition = context.destination.Position
	local distance = targetPosition - destinationPosition

	if context.seamlessAttributes.Scaled(context.teleporterConfiguration) then
		distance /= context.destination.Size
		if context.seamlessAttributes.Clamped(context.teleporterConfiguration) then
			distance = Vector3.new(
				math.clamp(distance.X, -0.5, 0.5),
				math.clamp(distance.Y, -0.5, 0.5),
				math.clamp(distance.Z, -0.5, 0.5)
			)
		end
		return context.destination.CFrame * CFrame.new(context.destination.Size * distance)
	else
		if context.seamlessAttributes.Clamped(context.teleporterConfiguration) then
			local destinationSize = context.destination.Size
			local sizeX, sizeY, sizeZ = destinationSize.X, destinationSize.Y, destinationSize.Z
			local halfSizeX, halfSizeY, halfSizeZ = sizeX / 2, sizeY / 2, sizeZ / 2
			distance = Vector3.new(
				math.clamp(distance.X, -halfSizeX, halfSizeX),
				math.clamp(distance.Y, -halfSizeY, halfSizeY),
				math.clamp(distance.Z, -halfSizeZ, halfSizeZ)
			)
		end
		return context.destination.CFrame * CFrame.new(distance)
	end
end

local function teleport(context: types.TeleportContext)
	local transitionKey = context.attributes.Transition(context.teleporterConfiguration)

	local tweenDuration = context.tweenAttributes.Duration(context.teleporterConfiguration)
	if tweenDuration == 0 then
		transitionKey = "Instant"
	end

	local transition = transitions[transitionKey]
	if transition then
		local transitionContext = context :: types.TransitionContext

		transitionContext.destinationCFrame = if context.seamlessAttributes.Enabled(context.teleporterConfiguration)
			then calculateSeamless(context)
			else (context.destination.CFrame * context.attributes.Offset(context.destinationConfiguration))

		-- TODO: calculate seamless camera cframe
		transitionContext.destinationCameraCFrame = Workspace.CurrentCamera.CFrame

		transition(transitionContext)
	end
end

return table.freeze {
	transitions = transitions,
	calculateSeamless = calculateSeamless,
	teleport = teleport,
	useAttributes = useAttributes,
	useSeamlessAttributes = useSeamlessAttributes,
}
