local Workspace = game:GetService("Workspace")

local tweens = require("@libs/tweens")
local types = require("@libs/teleport/types")

return function(context: types.TransitionContext)
	local life = context.teleporterLife:extend()

	if context.attributes.KeepVelocity(context.teleporterConfiguration) then
		local angularVelocity = context.target.AssemblyAngularVelocity
		local linearVelocity = context.target.AssemblyLinearVelocity

		life:add(function()
			context.target.AssemblyAngularVelocity = angularVelocity
			context.target.AssemblyLinearVelocity = linearVelocity
		end)
	end

	local wasAnchored = context.target.Anchored
	life:add(function()
		context.target.Anchored = wasAnchored
	end)

	context.target.Anchored = true
	context.target.AssemblyAngularVelocity = Vector3.zero
	context.target.AssemblyLinearVelocity = Vector3.zero

	local tweenConfiguration =
		tweens.configurationFromAttributes(context.tweenAttributes, context.teleporterConfiguration)

	local tween: Tween = life:addMany(
		tweens.playAlways(context.target, { CFrame = context.destinationCFrame }, tweenConfiguration),
		tweens.playAlways(Workspace.CurrentCamera, { CFrame = context.destinationCameraCFrame }, tweenConfiguration)
	)

	tween.Completed:Wait()
	life:destroy()
end
