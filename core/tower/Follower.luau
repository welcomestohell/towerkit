local Players = game:GetService "Players"
local Workspace = game:GetService "Workspace"

local character = require "@libs/character"
local functions = require "@libs/functions"
local std = require "@libs/std"
local tables = require "@libs/collections/tables"

local mouse = Players.LocalPlayer:GetMouse()

local Follower = std.Mechanic {
	emoji = "👀",
	name = "Follower",
	description = "Continously follows the target by looking at, rotating, positioning, or pivoting towards it.",
	instanceType = std.gt.instanceTree {
		Center = std.isA.BasePart(),
		Base = std.isA.BasePart(),
	},

	Enabled = std.Attribute("Enabled", std.gt.boolean(), true),
	Relative = std.Attribute("Relative", std.gt.boolean(), false),
	Mode = std.Attribute(
		"Mode",
		std.gt.literals("LookAt", "RotationOf", "PositionOf", "PivotOf", "None"),
		functions.literal "None"
	),
	Target = std.Attribute(
		"Target",
		std.gt.literals("Character", "Mouse", "Camera", "Pointer", "None"),
		functions.literal "None"
	),

	std.AttributeSection "Position Axes",
	XPosition = std.Attribute("XPosition", std.gt.boolean(), true),
	YPosition = std.Attribute("YPosition", std.gt.boolean(), true),
	ZPosition = std.Attribute("ZPosition", std.gt.boolean(), true),

	std.AttributeSection "Rotation Axes",
	XRotation = std.Attribute("XRotation", std.gt.boolean(), true),
	YRotation = std.Attribute("YRotation", std.gt.boolean(), true),
	ZRotation = std.Attribute("ZRotation", std.gt.boolean(), true),

	std.AttributeSection "Smoothness",
	Smooth = std.Attribute("Smooth", std.gt.boolean(), false),
	Responsiveness = std.Attribute("Responsiveness", std.gt.positiveNumber, 1),
}

export type FollowerMechanic = std.Mechanic<typeof(Follower)>
export type Mode = typeof(Follower.Mode:type())
export type Target = typeof(Follower.Target:type())

function Follower.getTargetCFrame(target: Target): CFrame?
	if target == "Camera" then
		return Workspace.CurrentCamera.CFrame
	elseif target == "Mouse" then
		return mouse.Hit
	elseif target == "Character" then
		local root = character.getMaybeHumanoidRootPart()
		if root then return root.CFrame end
	end
	return nil
end

function Follower.onPreSimulation(self: typeof(Follower), deltaTime: number, level: std.Level)
	local followers = level:getMechanics(self)
	local countFollowers = #followers

	if countFollowers == 0 then return end

	local shouldBulkMove = false
	local bulkInstances: { BasePart } = tables.create(countFollowers)
	local bulkCFrames: { CFrame } = tables.create(countFollowers)

	for _, follower: FollowerMechanic in followers do
		if not follower:Enabled() then continue end

		local targetCFrame = self.getTargetCFrame(follower:Target())
		if not targetCFrame then continue end

		-- Dear basketball

		local mode: Mode = follower:Mode()
		local center = follower.instance.Center
		if mode == "None" then
			continue
		elseif mode == "LookAt" then
			targetCFrame = CFrame.lookAt(center:GetPivot().Position, targetCFrame.Position)
		elseif mode == "PositionOf" then
			targetCFrame = CFrame.new(targetCFrame.Position)
		elseif mode == "RotationOf" then
			targetCFrame = CFrame.new(targetCFrame.Position) * center:GetPivot().Rotation
		end

		if follower:Relative() then
			targetCFrame *= center.Rotation
		end

		local current = center:GetPivot()

		local cx, cy, cz = current.Position.X, current.Position.Y, current.Position.Z
		local tx, ty, tz = targetCFrame.Position.X, targetCFrame.Position.Y, targetCFrame.Position.Z

		local rx, ry, rz = current:ToOrientation()
		local trx, try, trz = targetCFrame:ToOrientation()

		if not follower:XPosition() then tx = cx end
		if not follower:YPosition() then ty = cy end
		if not follower:ZPosition() then tz = cz end

		if not follower:XRotation() then trx = rx end
		if not follower:YRotation() then try = ry end
		if not follower:ZRotation() then trz = rz end

		targetCFrame = CFrame.new(tx, ty, tz) * CFrame.fromOrientation(trx, try, trz)

		if follower:Smooth() then
			local responsiveness = follower:Responsiveness()
			if responsiveness ~= 0 then
				targetCFrame = center.CFrame:Lerp(targetCFrame, 1 - math.exp(-deltaTime / responsiveness))
			end
		end

		table.insert(bulkInstances, follower.instance.Base)
		table.insert(bulkCFrames, targetCFrame)
		shouldBulkMove = true
	end

	if shouldBulkMove then Workspace:BulkMoveTo(bulkInstances, bulkCFrames) end
end

return Follower
