local Players = game:GetService("Players")

local std = require("@libs/std")

local character = require("@libs/character")
local damage = require("@libs/damage")
local gt = require("@pkgs/gt")
local sounds = require("@libs/sounds")

--[=[
	@class Turret
	@tag Mechanic

	Turret makes the instance shoot bullets based on its current orientation.
	
	It can also, optionally, make a noise when shooting.
]=]
local Turret = std.Mechanic({})
export type TurretMechanic = std.Mechanic<typeof(Turret)>

Turret.instanceTag = "Turret"
Turret.instanceType = std.gt.instanceTree(std.isA.Model(), {
	Base = std.isA.BasePart(),
	Bullet = std.gt.instanceTree(std.isA.BasePart(), {
		BulletAttachment = std.isA.Attachment(),
		BulletAlignOrientation = std.isA.AlignOrientation(),
		BulletVelocity = std.isA.LinearVelocity(),
	}),
})
Turret.debuggerEmoji = "🔫"

Turret.Enabled = Turret:withEnabled()

Turret:attributeSection("Bullets")
Turret.Firerate = Turret:attribute("Firerate", std.gt.positiveNumber, 1)
Turret.Speed = Turret:attribute("Speed", std.gt.positiveNumber, 25)
Turret.Acceleration = Turret:attribute("Acceleration", std.gt.Vector3(), Vector3.zero)
Turret.Lifetime = Turret:attribute("Lifetime", std.gt.positiveNumber, 2)
Turret.DestroyOnTouch = Turret:attribute("DestroyOnTouch", std.gt.boolean(), true)
Turret.IgnoreTag = Turret:attribute("IgnoreTag", std.gt.string(), "Ignore")

Turret:attributeSection("Damage")
Turret.Damage = damage.useAttributes(Turret)
Turret.Cooldown = Turret:attribute("Cooldown", std.gt.positiveNumber, 0.5)

Turret:attributeSection("Spread Angle")
Turret.SpreadAngle = Turret:attribute("SpreadAngle", std.gt.NumberRange, NumberRange.new(0, 0))

Turret:attributeSection("Sound")
Turret.FireSound = sounds.useAttributes(Turret, "FireSound")

Turret:attributeSection("Culling")
Turret.Range = Turret:attribute("Range", std.gt.positiveNumber, 50)

Turret:attributeSection("Tags")
Turret.FireBasename = Turret:attribute("FireBasename", gt.string(), "TurretFire")
Turret.ExpireBasename = Turret:attribute("ExpireBasename", gt.string(), "TurretExpire")

Turret.cooldowns = {} :: { [Player]: number }

function Turret.onTouch(turret: TurretMechanic, hit: BasePart): boolean
	if not hit or not hit.Parent or not character.isFromMaybeCharacter(hit) then
		return false
	end

	local player = character.getPlayerFromHit(hit)

	if not player then
		return false
	end

	local turretDamage, turretCooldown = turret:Damage(), turret:Cooldown()
	local cooldowns = turret.cooldowns or {}

	local now = os.clock()

	if cooldowns[player] and cooldowns[player] > now then
		return false
	end

	cooldowns[player] = now + turretCooldown
	damage.damagePlayer(player, turretDamage)

	return true
end

function Turret.calculateSpreadAngle(turret: TurretMechanic, direction: Vector3): Vector3
	local spreadAngle: NumberRange = turret:SpreadAngle()

	local directionCFrame = CFrame.new(Vector3.zero, direction)
	local spreadDirection = CFrame.fromOrientation(0, 0, math.random(0, math.pi * 2))
	local spreadAngle = CFrame.fromOrientation(math.rad(math.random(spreadAngle.Min, spreadAngle.Max)), 0, 0)

	return (directionCFrame * spreadDirection * spreadAngle).LookVector
end

function Turret.fireBullet(turret: TurretMechanic, bulletTemplate: Part)
	local instance = turret.instance
	local primaryPart = instance.PrimaryPart

	if not primaryPart then
		return
	end

	if turret.FireSound.Play(turret) then
		sounds.playInstance(turret.FireSound, instance, turret.instanceConfiguration, sounds.sfx.tick)
	end

	for _, descendant in instance:GetDescendants() do
		if descendant:HasTag("TurretFireParticle") and descendant:IsA("ParticleEmitter") then
			descendant:Emit(descendant.Rate)
		end
	end

	local bulletLife = turret.life:extend()
	local bulletInstance = bulletLife:add(bulletTemplate:Clone())

	local function cleanup()
		bulletLife:destroy()
	end

	local spawnCFrame: CFrame = primaryPart.CFrame
	local spreadAngle = turret:calculateSpreadAngle(spawnCFrame.LookVector)

	bulletInstance.CFrame = spawnCFrame

	local mainAttachment = bulletInstance:FindFirstChildOfClass("Attachment")
	local linearVelocity = bulletInstance:FindFirstChildOfClass("LinearVelocity")

	if not mainAttachment or not linearVelocity then
		cleanup()

		return
	end

	local finalCFrame = CFrame.lookAt(spawnCFrame.Position, spawnCFrame.Position + spreadAngle)

	linearVelocity.Attachment0 = mainAttachment
	linearVelocity.VectorVelocity = finalCFrame.LookVector * turret:Speed()

	local alignOrientation = bulletInstance:FindFirstChildOfClass("AlignOrientation")

	if not alignOrientation then
		cleanup()

		return
	end

	alignOrientation.Attachment0 = mainAttachment
	alignOrientation.CFrame = primaryPart.CFrame.Rotation

	bulletInstance.Anchored = false
	bulletInstance.Parent = instance

	bulletLife:add(bulletInstance.Touched:Connect(function(hit)
		local destroyOnTouch = turret:DestroyOnTouch()
		local validHit = turret:onTouch(hit)

		if destroyOnTouch or validHit then
			cleanup()
		end
	end))

	bulletLife:add(function()
		task.delay(turret:Lifetime(), cleanup)
	end)
end

function Turret.onStart(self: typeof(Turret), turret: TurretMechanic, level: std.Level)
	local instance = turret.instance
	local primaryPart = instance.PrimaryPart

	if not primaryPart then
		turret.log:error("Turret", instance:GetFullName(), "is missing the PrimaryPart.")

		return
	end

	local bulletTemplate = instance.Bullet

	bulletTemplate.Parent = nil

	turret.life:spawn(function()
		while turret.life.destroyed == false do
			local firerate = turret:Firerate()
			local enabled = turret:Enabled()

			task.wait(1 / firerate)

			if not enabled then
				continue
			end

			local distance = Players.LocalPlayer:DistanceFromCharacter(primaryPart.Position)
			local range = turret:Range()

			if distance <= range then
				turret:fireBullet(bulletTemplate)
			end
		end
	end)
end

return Turret
