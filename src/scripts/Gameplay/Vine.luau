local activation = require("@libs/activation")
local character = require("@libs/character")
local constraints = require("@libs/constraints")
local sounds = require("@libs/sounds")
local std = require("@libs/std")

local Vine = std.Mechanic({})
export type VineMechanic = std.Mechanic<typeof(Vine)> & { templateHandle: BasePart? }
Vine.instanceTag = "Vine"
Vine.instanceType = std.gt.instanceTree {
	Top = std.isA.BasePart(),
	Activator = std.isA.BasePart(),
	Constraint = std.gt.optional(std.isA.Constraint()),
	Handle = std.gt.optional(std.isA.BasePart()),
}
Vine.debuggerEmoji = "🪝"

Vine.Enabled = Vine:withEnabled()
Vine.Cooldown = Vine:attribute("Cooldown", std.gt.positiveNumber, 0)
Vine.Debounced = Vine:attribute("Debounced", std.gt.boolean(), false)
Vine.KeepVelocity = Vine:attribute("KeepVelocity", std.gt.boolean(), true)

Vine:attributeSection("Activation")
Vine.Activation = activation.useAttributes(Vine)

Vine:attributeSection("Dismount")
Vine.Dismount = activation.useAttributes(Vine, "Dismount")

Vine:attributeSection("Sound Effects")
Vine.GrabSound = sounds.useAttributes(Vine, "GrabSound")
Vine.JumpSound = sounds.useAttributes(Vine, "JumpSound")

function Vine.useTemplateConstraint(vine: VineMechanic): Constraint
	if vine.instance.Constraint then
		return vine.instance.Constraint
	end

	local rope: RopeConstraint = vine.life:add(Instance.new("RopeConstraint"))
	rope.Name = "Constraint"
	rope.Color = BrickColor.new(vine.instance.Top.Color)
	rope.Parent = vine.instance

	return rope
end

function Vine.useTemplateHandle(vine: VineMechanic): BasePart
	if vine.templateHandle then
		return vine.templateHandle
	end

	local handle: Part = vine.life:add(Instance.new("Part"))
	handle.Name = "Handle"
	handle.Color = vine.instance.Color
	handle.Size = Vector3.new(3, 0.5, 0.5)
	handle.Material = Enum.Material.SmoothPlastic

	vine.templateHandle = handle
	return handle
end

function Vine.onActivate(self: typeof(Vine), vine: VineMechanic, level: std.Level)
	if not vine:Enabled() or vine:Debounced() then
		return
	end

	local root = character.getMaybeHumanoidRootPart()
	if not root then
		return
	end

	vine:Debounced(true)
	self.Activation.Enabled(vine, false)

	local angularVelocity, linearVelocity = Vector3.zero, Vector3.zero
	if vine:KeepVelocity() then
		angularVelocity, linearVelocity = root.AssemblyAngularVelocity, root.AssemblyLinearVelocity
	end

	local attachmentTrove = vine.life:extend()

	local constraint = attachmentTrove:add(vine:useTemplateConstraint():Clone())
	local handle = attachmentTrove:add(vine:useTemplateHandle():Clone())
	local attachment0, attachment1 = constraints.populateAttachments(attachmentTrove, constraint)
	attachment0.Parent, attachment1.Parent = vine.instance.Top, handle

	
end

return Vine
