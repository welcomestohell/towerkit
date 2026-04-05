local Players = game:GetService("Players")
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

	context.target.Anchored = true
	context.target.AssemblyAngularVelocity = Vector3.zero
	context.target.AssemblyLinearVelocity = Vector3.zero

	local screen = life:add(Instance.new("ScreenGui"))
	screen.Name = "ScreenFadeTeleport"
	screen.ResetOnSpawn = false
	screen.IgnoreGuiInset = true

	local frame = life:add(Instance.new("Frame"))
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundColor3 = context.attributes.ScreenFadeColor(context.teleporterConfiguration)
	frame.BackgroundTransparency = 1

	frame.Parent = screen
	screen.Parent = Players.LocalPlayer.PlayerGui

	local tweenConfiguration =
		tweens.configurationFromAttributes(context.tweenAttributes, context.teleporterConfiguration)
	tweenConfiguration.duration = tweenConfiguration.duration and tweenConfiguration.duration / 2 or 0
	tweenConfiguration.isReversed = true

	life:add(tweens.playAlways(frame, { BackgroundTransparency = 0 }, tweenConfiguration))

	task.wait(tweenConfiguration.duration)
	context.target:PivotTo(context.destinationCFrame)
	Workspace.CurrentCamera:PivotTo(context.destinationCameraCFrame)

	task.wait(tweenConfiguration.duration)
	life:destroy()
	context.target.Anchored = wasAnchored
end
