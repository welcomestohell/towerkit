local Workspace = game:GetService("Workspace")

local types = require("@libs/teleport/types")

return function(context: types.TransitionContext)
	context.target:PivotTo(context.destinationCFrame)
	Workspace.CurrentCamera.CFrame = context.destinationCameraCFrame

	if context.attributes.KeepVelocity(context.teleporterConfiguration) ~= true then
		context.target.AssemblyAngularVelocity = Vector3.zero
		context.target.AssemblyLinearVelocity = Vector3.zero
	end
end
