local Workspace = game:GetService "Workspace"

local activation = require "@libs/activation"
local std = require "@libs/std"
local tweens = require "@libs/tweens"

local Camera = std.Mechanic {}
export type CameraMechanic = std.Mechanic<typeof(Camera)>
Camera.name = "Camera"
Camera.instanceType = std.gt.union(std.isA.BasePart(), std.isA.Camera())
Camera.emoji = "📷"

Camera:attributeSection "Activation"
Camera.Activation = activation.useAttributes(Camera)

Camera:attributeSection "Transition"
Camera.Transition = tweens.useAttributes(Camera)

function Camera:onActivate(camera: CameraMechanic)
	Workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
	tweens.play(
		Workspace.CurrentCamera,
		{ CFrame = camera.instance.CFrame },
		tweens.configurationFromAttributes(camera.Transition, camera.instanceConfiguration or camera.instance)
	)
end

return Camera
