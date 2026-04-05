local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local character = require("@libs/character")
local functions = require("@libs/functions")
local std = require("@libs/std")
local tables = require("@libs/collections/tables")

local mouse = Players.LocalPlayer:GetMouse()

--[=[
	@class Follower
	@tag Mechanic

	Follower makes the instance follow the player's character/camera/mouse/pointer.

	The instance can follow by looking towards the target, or taking the rotation/position/pivot of the target.
]=]
local Follower = std.Mechanic({})
export type FollowerMechanic = std.Mechanic<typeof(Follower)>

Follower.instanceTag = "Follower"
Follower.instanceType = std.isA.BasePart()
Follower.debuggerEmoji = "👀"

Follower.Enabled = Follower:withEnabled()

Follower.FollowMode = Follower:attribute(
	"FollowMode",
	std.gt.unionLiterals5("LookAt", "RotationOf", "PositionOf", "PivotOf", "None"),
	functions.literal "None"
)

Follower.FollowTarget = Follower:attribute(
	"FollowTarget",
	std.gt.unionLiterals5("Character", "Mouse", "Camera", "Pointer", "None"),
	functions.literal "None"
)

Follower:attributeSection("Origin")
Follower.Origin = Follower:attribute("Origin", std.gt.optional(std.gt.CFrame()), nil)
Follower.UseOriginRotation = Follower:attribute("UseOriginRotation", std.gt.boolean(), false)

Follower:attributeSection("Position Axes")
Follower.UseXPosition = Follower:attribute("UseXPosition", std.gt.boolean(), true)
Follower.UseYPosition = Follower:attribute("UseYPosition", std.gt.boolean(), true)
Follower.UseZPosition = Follower:attribute("UseZPosition", std.gt.boolean(), true)

Follower:attributeSection("Rotation Axes")
Follower.UseXRotation = Follower:attribute("UseXRotation", std.gt.boolean(), true)
Follower.UseYRotation = Follower:attribute("UseYRotation", std.gt.boolean(), true)
Follower.UseZRotation = Follower:attribute("UseZRotation", std.gt.boolean(), true)

Follower:attributeSection("Smoothness")
Follower.Smooth = Follower:attribute("Smooth", std.gt.boolean(), false)
Follower.Responsiveness = Follower:attribute("Responsiveness", std.gt.positiveNumber, 1)

export type FollowMode = typeof(Follower.FollowMode:type())
export type FollowTarget = typeof(Follower.FollowTarget:type())

function Follower.getTargetCFrame(target: FollowTarget): CFrame?
	if target == "Camera" then
		return Workspace.CurrentCamera.CFrame
	elseif target == "Mouse" then
		return mouse.Hit
	elseif target == "Character" then
		local root = character.getMaybeHumanoidRootPart()
		if root then
			return root.CFrame
		end
	end
	return nil
end

function Follower:onStart(follower: FollowerMechanic)
	follower.Origin:getOrSet(follower, follower.instance.CFrame :: CFrame?)
end

function Follower.onPreSimulation(self: typeof(Follower), deltaTime: number, level: std.Level)
	local followers = level:getMechanics(self)
	local countFollowers = #followers

	if countFollowers == 0 then
		return
	end

	local shouldBulkMove = false
	local bulkInstances: { BasePart } = tables.create(countFollowers)
	local bulkCFrames: { CFrame } = tables.create(countFollowers)

	for _, follower in followers do
		if not follower:Enabled() then
			continue
		end

		local targetCFrame = self.getTargetCFrame(follower:FollowTarget())
		if not targetCFrame then
			continue
		end

		-- Dear basketball

		local mode: FollowMode = follower:FollowMode()
		local instance = follower.instance
		if mode == "None" then
			continue
		elseif mode == "LookAt" then
			targetCFrame = CFrame.lookAt(instance:GetPivot().Position, targetCFrame.Position)
		elseif mode == "PositionOf" then
			targetCFrame = CFrame.new(targetCFrame.Position)
		elseif mode == "RotationOf" then
			targetCFrame = CFrame.new(targetCFrame.Position) * instance:GetPivot().Rotation
		end

		local baseTransform = follower:Origin()
		local useRelative = follower:UseOriginRotation()
		if useRelative and baseTransform then
			targetCFrame *= baseTransform.Rotation
		end

		local current = instance:GetPivot()

		local cx, cy, cz = current.Position.X, current.Position.Y, current.Position.Z
		local tx, ty, tz = targetCFrame.Position.X, targetCFrame.Position.Y, targetCFrame.Position.Z

		local rx, ry, rz = current:ToEulerAnglesXYZ()
		local trx, try, trz = targetCFrame:ToEulerAnglesXYZ()

		-- FIXME: ts is misbehaving ??????????

		if not follower:UseXPosition() then
			tx = cx
		end

		if not follower:UseYPosition() then
			ty = cy
		end

		if not follower:UseZPosition() then
			tz = cz
		end

		if not follower:UseXRotation() then
			trx = rx
		end

		if not follower:UseYRotation() then
			try = ry
		end

		if not follower:UseZRotation() then
			trz = rz
		end

		targetCFrame = CFrame.new(tx, ty, tz) * CFrame.fromEulerAnglesXYZ(trx, try, trz)

		if follower:Smooth() then
			local responsiveness = follower:Responsiveness()
			if responsiveness ~= 0 then
				targetCFrame = instance.CFrame:Lerp(targetCFrame, 1 - math.exp(-deltaTime / responsiveness))
			end
		end

		table.insert(bulkInstances, instance)
		table.insert(bulkCFrames, targetCFrame)
		shouldBulkMove = true
	end

	if shouldBulkMove then
		Workspace:BulkMoveTo(bulkInstances, bulkCFrames)
	end
end

return Follower
