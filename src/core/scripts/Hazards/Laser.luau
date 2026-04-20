local std = require("@libs/std")

local Laser = std.Mechanic({})
export type LaserMechanic = std.Mechanic<typeof(Laser)>

Laser.basename = "Laser"
Laser.instanceType = std.gt.instanceTree({
	Base = std.isA.BasePart(),
	Beam = std.isA.BasePart(),
})
Laser.debuggerEmoji = "🔦"

function Laser.onPreSimulation(self: typeof(Laser), laser: LaserMechanic, level: std.Level) end

return Laser

--[[
Ref code from old repo:

local player = game.Players.LocalPlayer
local LaserScript = {}

function LaserScript.init(laserPart: Instance)
	local laser = laserPart.Parent
	local currentHit = laser:FindFirstChildOfClass("ObjectValue")
	local laserShot = laser:FindFirstChild("LaserShot")
	
	if laserPart:IsA("BasePart") and currentHit and (laserShot and laserShot:IsA("BasePart") or laserPart:GetAttribute("Ray")) then
		local raycastParameters = RaycastParams.new()
		raycastParameters.FilterType = Enum.RaycastFilterType.Exclude
		raycastParameters.FilterDescendantsInstances = {(if laserPart:GetAttribute("IgnoreParts") then workspace[player.Team.Name] else nil), (if laserPart:GetAttribute("IgnorePlayers") then player.Character else nil)}
		
		game:GetService("RunService").RenderStepped:Connect(function()
			if laserPart:GetAttribute("Ray") then
				local ray = workspace:Raycast((laserPart.CFrame + laserPart.CFrame.LookVector * (laserPart.Size.Z / 2)).Position, laserPart.CFrame.LookVector * (laserPart:GetAttribute("Distance") or 10), raycastParameters)
				
				if ray and ray.Instance ~= currentHit.Value then
					currentHit.Value = ray.Instance
				end
			else
				local laserCast = workspace:Blockcast(laserPart.CFrame + laserPart.CFrame.LookVector * (laserPart.Size.Z / 2),
					Vector3.new(laserPart.Size.X - 1, laserPart.Size.Y - 1, 0.1),
					laserPart.CFrame.LookVector * (laserPart:GetAttribute("Distance") or 10), raycastParameters)
				
				if laserCast and laserCast.Distance <= (laserPart:GetAttribute("Distance") or 10) then
					laserShot.CFrame = laserPart.CFrame + laserPart.CFrame.LookVector * ((laserPart.Size.Z + laserCast.Distance) / 2)
					laserShot.Size = Vector3.new(laserShot.Size.X, laserShot.Size.Y, laserCast.Distance)
					
					if laserCast.Instance ~= currentHit.Value then
						currentHit.Value = laserCast.Instance
					end
				else
					laserShot.CFrame = laserPart.CFrame + laserPart.CFrame.LookVector * ((laserPart.Size.Z + (laserPart:GetAttribute("Distance") or 10)) / 2)
					laserShot.Size = Vector3.new(laserShot.Size.X, laserShot.Size.Y, (laserPart:GetAttribute("Distance") or 10))
				end
			end
		end)
	end
end

return LaserScript
]]
