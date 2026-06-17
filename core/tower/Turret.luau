const assets = require "@core/assets"
const emission = require "@libs/emission"
const logger = require "@core/shared/logger"
const Level = require "@libs/core/Level"
const sounds = require "@libs/sounds"
const std = require "@libs/std"
const touch = require "@libs/touch"

const Turret = std.Mechanic {
	emoji = "🔫",
	name = "Turret",
	description = "Continously shoot bullets based on its current orientation.",
	instanceType = std.gt.instanceTree(std.isA.Model(), {
		Bullet = std.gt.instanceTree(std.isA.BasePart(), {
			BulletAttachment = std.isA.Attachment(),
			BulletAlignOrientation = std.isA.AlignOrientation(),
			BulletVelocity = std.isA.LinearVelocity(),
		}),
	}),

	Enabled = std.Attribute("Enabled", std.gt.boolean(), true),
	SpreadAngle = std.Attribute("SpreadAngle", std.gt.NumberRange, NumberRange.new(0, 0)),

	std.AttributeSection "Bullets",
	Firerate = std.Attribute("Firerate", std.gt.positiveNumber, 1),
	Speed = std.Attribute("Speed", std.gt.positiveNumber, 25),
	Acceleration = std.Attribute("Acceleration", std.gt.Vector3(), Vector3.zero),
	Lifetime = std.Attribute("Lifetime", std.gt.positiveNumber, 2),
	DestroyOnTouch = std.Attribute("DestroyOnTouch", std.gt.boolean(), true),

	std.AttributeSection "Tags",
	IgnoreTag = std.Attribute("IgnoreTag", std.gt.tag, "Turret: Ignore"),
	EmitFireTag = std.Attribute("EmitFireTag", std.gt.tag, "Turret: On Fire"),
	EmitTouchTag = std.Attribute("EmitTouchTag", std.gt.tag, "Turret: On Touch"),
	EmitExpireTag = std.Attribute("EmitExpireTag", std.gt.tag, "Turret: On Expire"),

	std.AttributeSection "Sound",
	Sound = sounds.useAttributes(),

	std.AttributeSection "Touch",
	Touch = touch.useAttributes(),
}

export type TurretMechanic = std.Mechanic<typeof(Turret), { template: Bullet }>
export type Bullet = typeof(Turret.instanceType.Bullet)

function Turret.calculateSpreadAngle(turret: TurretMechanic, direction: Vector3): Vector3
	local spreadAngle: NumberRange = turret:SpreadAngle()

	local directionCFrame = CFrame.new(Vector3.zero, direction)
	local spreadDirection = CFrame.fromOrientation(0, 0, math.random() * math.tau)
	local spreadAngle =
		CFrame.fromOrientation(math.rad(spreadAngle.Min + math.random() * (spreadAngle.Max - spreadAngle.Min)), 0, 0)

	return (directionCFrame * spreadDirection * spreadAngle).LookVector
end

function Turret.onActivate(self: typeof(Turret), turret: TurretMechanic)
	local instance = turret.instance
	local primaryPart = instance.PrimaryPart

	if not primaryPart then return end

	if turret.Sound.Play(turret) then
		sounds.playInstance(turret.Sound, instance, turret.instanceConfiguration, assets.sfx.tick)
	end

	emission.emitTaggedDescendants(instance, turret:EmitFireTag())

	local bulletLife = turret.life:extend()
	local bulletInstance = bulletLife:add(turret.template:Clone())

	local function cleanup(isTouch: boolean?)
		emission.emitTaggedDescendants(
			bulletInstance,
			if isTouch then turret:EmitTouchTag() else turret:EmitExpireTag()
		)
		bulletLife:destroy()
	end

	local spawnCFrame: CFrame = primaryPart.CFrame
	local spreadAngle = turret:calculateSpreadAngle(spawnCFrame.LookVector)

	bulletInstance.Massless = true
	bulletInstance:PivotTo(spawnCFrame)

	local mainAttachment = bulletInstance:FindFirstChildOfClass "Attachment"
	local linearVelocity = bulletInstance:FindFirstChildOfClass "LinearVelocity"
	local alignOrientation = bulletInstance:FindFirstChildOfClass "AlignOrientation"

	if not mainAttachment or not linearVelocity or not alignOrientation then return cleanup() end

	local finalCFrame = CFrame.lookAt(spawnCFrame.Position, spawnCFrame.Position + spreadAngle)

	linearVelocity.Attachment0 = mainAttachment
	linearVelocity.VectorVelocity = finalCFrame.LookVector * turret:Speed()
	linearVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
	linearVelocity.MaxForce = math.huge

	alignOrientation.Attachment0 = mainAttachment
	alignOrientation.CFrame = primaryPart.CFrame.Rotation

	bulletInstance.Anchored = false
	bulletInstance.Parent = instance

	bulletLife:add(bulletInstance.Touched:Connect(function(toucher)
		local destroyOnTouch = turret:DestroyOnTouch()
		local isTouched = destroyOnTouch
			and not toucher:IsDescendantOf(turret.instance)
			and not toucher:HasTag(turret:IgnoreTag())
			and (
				toucher.CanCollide
				or touch.isToucherValid(turret.Touch, turret.instance, turret.instanceConfiguration, toucher)
			)

		if isTouched then cleanup(true) end
	end))

	bulletLife:delay(turret:Lifetime(), cleanup, nil)
end

function Turret.onStart(self: typeof(Turret), turret: TurretMechanic, level: std.Level)
	local instance = turret.instance
	local primaryPart = instance.PrimaryPart

	if not primaryPart then
		logger:Error("Turret", instance:GetFullName(), "is missing the PrimaryPart.")
		return
	end

	-- Turret is already loaded by the time this is called. We add the tag here
	-- so spawned bullets don't automatically load until we're done intializing
	-- them.
	turret.instance:AddTag(Level.DO_NOT_LOAD_TAG)

	turret.template = turret.life:add(instance.Bullet)
	turret.template.Parent = nil
	turret.template:AddTag "Bullet"

	turret.life:spawn(function()
		while not turret.life.destroyed do
			task.wait(1 / turret:Firerate())
			if turret:Enabled() then self:onActivate(turret) end
		end
	end)
end

return Turret
