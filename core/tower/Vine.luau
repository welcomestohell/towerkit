const activation = require "@libs/activation"
local Attribute = require "@libs/attributes/Attribute"
local character = require "@libs/character"
local constraints = require "@libs/constraints"
local emission = require "@libs/emission"
const std = require "@libs/std"
local tweens = require "@libs/tweens"

const Vine = std.Mechanic {
	emoji = "🪝",
	name = "Vine",
	description = "When activated, attaches the player or a Box to itself using a given Constraint.",
	instanceType = std.gt.instanceTree {
		Activator = std.isA.BasePart(),
		Constraint = std.isA.Constraint(),
		Base = std.gt.instanceTree(std.isA.BasePart(), {
			BaseAttachment = std.isA.Attachment(),
		}),
		Handle = std.gt.instanceTree(std.isA.BasePart(), {
			HandleAttachment = std.isA.Attachment(),
		}),
	},

	-- TODO: implement animations
	Animated = std.Attribute("Animated", std.gt.boolean(), true),
	Cooldown = std.Attribute("Cooldown", std.gt.positiveNumber, 0),
	KeepMomentum = std.Attribute("KeepMomentum", std.gt.boolean(), true),
	JumpOnDismount = std.Attribute("JumpOnDismount", std.gt.boolean(), true),

	ActivatorTransparency = std.Attribute("ActivatorTransparency", std.gt.constrainNumber(0, 1), 0),
	ActivatorPosition = std.Attribute("ActivatorCFrame", std.gt.Vector3(), Vector3.zero),
	ActivatorSize = std.Attribute("ActivatorSize", std.gt.Vector3(), Vector3.zero),

	std.AttributeSection "Activation",
	Activation = activation.useAttributes(),

	std.AttributeSection "Deactivation",
	Deactivation = activation.useAttributes "Deactivation",

	std.AttributeSection "Tags",
	EmitActivatedTag = std.Attribute("EmitActivatedTag", std.gt.tag, "Vine: On Activated"),
	EmitDeactivatedTag = std.Attribute("EmitDeactivatedTag", std.gt.tag, "Vine: On Deactivated"),
	EmitJumpedTag = std.Attribute("EmitJumpTag", std.gt.tag, "Vine: On Jumped"),
	EmitRefreshedTag = std.Attribute("EmitRefreshedTag", std.gt.tag, "Vine: On Refreshed"),

	std.AttributeSection "Tweens",
	ActivatorTween = tweens.useAttributes "ActivatorTween",

	active = {},
}

export type VineMechanic = std.Mechanic<typeof(Vine), { handle: BasePart }>

function Vine.getActivationInstances(self: typeof(Vine), vine: VineMechanic)
	return vine.instance.Activator
end

function Vine.onStart(self: typeof(Vine), vine: VineMechanic)
	vine.handle = vine.instance.Handle
	vine.handle.Parent = nil
	self.ActivatorTransparency(vine, vine.instance.Activator.Transparency)
	self.ActivatorPosition(vine, vine.instance.Activator.Position)
	self.ActivatorSize(vine, vine.instance.Activator.Size)
end

function Vine.onActivate(self: typeof(Vine), vine: VineMechanic, level: std.Level, event: activation.ActivationEvent)
	const toucher = if event.kind == "Touch" and not character.isFromCharacter(event.toucher)
		then event.toucher
		else character.getCharacter().Head

	if self.active[toucher] then return end
	self.active[toucher] = true

	const isPlayer = character.isFromCharacter(toucher)

	const deactivationLife = vine.life:extend()
	deactivationLife:destroyOn(toucher.Destroying)
	self.Activation.Enabled(vine, false)

	vine.instance.Activator.Transparency = 1
	vine.instance.Activator.Position = vine.instance.Base.Position
	vine.instance.Activator.Size = Vector3.zero

	const handle = deactivationLife:add(vine.handle:Clone())
	handle.CFrame = toucher.CFrame + toucher.CFrame.UpVector * (toucher.Size.Y / 2)
	handle.Anchored = false
	handle.Parent = vine.instance
	constraints.weld(deactivationLife, handle, toucher)

	const constraint = deactivationLife:add(vine.instance.Constraint:Clone())
	constraint.Color = vine.instance.Activator.BrickColor
	constraint.Attachment0 = handle:FindFirstChild "HandleAttachment" :: Attachment
	constraint.Attachment1 = vine.instance.Base:FindFirstChild "BaseAttachment" :: Attachment
	constraint.Enabled = true
	constraint.Parent = handle

	emission.emitTaggedDescendants(vine.instance, vine:EmitActivatedTag())

	deactivationLife:add(function()
		self.active[toucher] = nil

		if toucher and vine:KeepMomentum() == false then toucher.AssemblyLinearVelocity = Vector3.zero end

		if isPlayer then
			const humanoid = character.getMaybeHumanoid()
			if humanoid then
				humanoid.PlatformStand = false
				if vine:JumpOnDismount() then humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end
				emission.emitTaggedDescendants(vine.instance, vine:EmitJumpedTag())
			end
		end

		emission.emitTaggedDescendants(vine.instance, vine:EmitDeactivatedTag())

		const cooldown = vine:Cooldown()
		vine.life:delay(cooldown, emission.emitTaggedDescendants, vine.instance, vine:EmitRefreshedTag())
		vine.life:delay(cooldown, Attribute.set :: any, self.Activation.Enabled, vine, true)
		vine.life:delay(
			cooldown,
			tweens.playFromAttributes,
			vine.instance.Activator,
			{
				Transparency = vine:ActivatorTransparency(),
				Position = vine:ActivatorPosition(),
				Size = vine:ActivatorSize(),
			} :: { [string]: unknown },
			vine.ActivatorTween,
			vine.instanceConfiguration
		)
	end)

	activation.bindActivation {
		instanceLife = deactivationLife,
		instance = vine.instance.Activator,
		instanceConfiguration = vine.instanceConfiguration,
		attributes = self.Deactivation,

		onActivate = deactivationLife:wrapDestroy() :: (...any) -> (),
	}
end

return Vine
