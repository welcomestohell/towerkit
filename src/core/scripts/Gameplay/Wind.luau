local character = require("@libs/character")
local std = require("@libs/std")
local threadpool = require("@libs/threadpool")

local Wind = std.Mechanic({})
export type WindMechanic = std.Mechanic<typeof(Wind)>
Wind.basename = "Wind"
Wind.instanceType = std.isA.BasePart()
Wind.debuggerEmoji = "💨"

Wind.Speed = Wind:attribute("Speed", std.gt.number(), 40)
Wind.MaxForce = Wind:attribute("MaxForce", std.gt.number(), math.huge)
Wind.Direction = Wind:attribute("Direction", std.gt.Vector3(), Vector3.zero)
Wind.ContinuousUpdates = Wind:attribute("ContinuousUpdates", std.gt.boolean(), true)

local UPDATE_INTERVAL = 1 / 30

function Wind:onStart(wind: WindMechanic)
	local touching = {}

	wind.instance.Touched:Connect(function(hit)
		local root = character.getMaybeHumanoidRootPart(hit)
		if not root or touching[root] then
			return
		end

		touching[root] = true

		local attachment = Instance.new("Attachment")
		attachment.Parent = root

		local velocity = Instance.new("LinearVelocity")
		velocity.Attachment0 = attachment
		velocity.RelativeTo = Enum.ActuatorRelativeTo.World
		velocity.ForceLimitMode = Enum.ForceLimitMode.PerAxis
		velocity.MaxAxesForce = Vector3.one * wind:MaxForce()
		velocity.VectorVelocity = wind.instance.CFrame:VectorToWorldSpace(wind:Direction()) * wind:Speed()
		velocity.Parent = root

		wind.life:add(threadpool.spawn(function()
			while touching[root] and root.Parent and wind.instance:IsDescendantOf(workspace) do
				if wind:ContinuousUpdates() then
					velocity.VectorVelocity = wind.instance.CFrame:VectorToWorldSpace(wind:Direction()) * wind:Speed()
				end

				task.wait(UPDATE_INTERVAL)
			end

			velocity:Destroy()
			attachment:Destroy()
		end))
	end)

	wind.instance.TouchEnded:Connect(function(hit)
		local root = character.getMaybeHumanoidRootPart(hit)
		if root then
			touching[root] = nil
		end
	end)
end

return Wind
