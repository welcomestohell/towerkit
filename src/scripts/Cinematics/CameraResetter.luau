local Workspace = game:GetService("Workspace")

local activation = require("@libs/activation")
local std = require("@libs/std")

local CameraResetter = std.Mechanic({})
export type CameraResetterMechanic = std.Mechanic<typeof(CameraResetter)>
CameraResetter.instanceTag = "CameraResetter"
CameraResetter.instanceType = std.isA.Instance()
CameraResetter.debuggerEmoji = "🔄"

CameraResetter:attributeSection("Activation")
CameraResetter.Activation = activation.useAttributes(CameraResetter)

function CameraResetter:onActivate()
	Workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
end

return CameraResetter
