const emission = require "@libs/emission"
const std = require "@libs/std"
const toggle = require "@libs/toggle"

const RELEASE_FORCE = Vector3.one * math.huge
const RELEASE_VELOCITY = math.huge

const Descender = std.Mechanic {
	emoji = "⬇️",
	name = "Descender",
	description = "Descends with the weight of other instances to disable itself when it reaches it's End part.",
	instanceType = std.gt.instanceTree {
		Base = std.gt.instanceTree(std.isA.BasePart(), {
			AlignPosition = std.isA.AlignPosition(),
			PrismaticConstraint = std.isA.PrismaticConstraint(),
		}),
		End = std.isA.BasePart(),
	},

	Enabled = std.Attribute("Enabled", std.gt.boolean(), true),
	Active = std.Attribute("Active", std.gt.boolean(), false),
	Mass = std.Attribute("Mass", std.gt.positiveNumber, 12.6),

	std.AttributeSection "Toggle",
	ToggleDuration = std.Attribute("ToggleDuration", std.gt.positiveNumber, 1.5),
	ToggleConnectedParts = std.Attribute("ToggleConnectedParts", std.gt.boolean(), true),

	std.AttributeSection "Emission",
	EmitToggledTag = std.Attribute("EmitToggledTag", std.gt.tag, "Descender: On Toggled"),
	EmitRespawnedTag = std.Attribute("EmitRespawnedTag", std.gt.tag, "Descender: On Respawned"),
}

export type DescenderMechanic = std.Mechanic<typeof(Descender)>

function Descender.onStart(self: typeof(Descender), descender: DescenderMechanic, level: std.Level)
	const base = descender.instance.Base
	const align = base.AlignPosition

	descender.life:add(self.Mass:onBind(descender, function(mass: number)
		const oldProperties = base.CustomPhysicalProperties
		const densityMultiplier = 1 / (base.Mass * oldProperties.Density)
		base.CustomPhysicalProperties = PhysicalProperties.new(
			densityMultiplier * mass,
			oldProperties.Friction,
			oldProperties.Elasticity,
			oldProperties.FrictionWeight,
			oldProperties.ElasticityWeight
		)
		align.MaxAxesForce = Vector3.yAxis * ((workspace.Gravity * base.Mass) + 58)
	end))

	align.ForceLimitMode = Enum.ForceLimitMode.PerAxis
	align.ForceRelativeTo = Enum.ActuatorRelativeTo.World
	align.Position = base.Position
	base.Anchored = false

	if descender:ToggleConnectedParts() then
		for _, connected in base:GetConnectedParts(true) do
			connected.Massless = connected ~= descender
		end
	end

	descender.life:add(descender.instance.End.Touched:Connect(function(toucher: BasePart)
		if toucher ~= base or descender:Active() or not descender:Enabled() then return end
		descender:Active(true)

		const oldForce = align.MaxAxesForce
		const oldVelocity = align.MaxVelocity

		emission.emitTaggedDescendants(descender.instance, descender:EmitToggledTag())
		if descender:ToggleConnectedParts() then
			for _, connected in base:GetConnectedParts(true) do
				toggle.toggleInstance(false, connected)
			end
		else
			toggle.toggleInstance(false, base)
		end

		align.MaxAxesForce = RELEASE_FORCE
		align.MaxVelocity = RELEASE_VELOCITY

		task.wait(descender:ToggleDuration())

		-- By now, the falling platform could be destroyed, so we check again.
		if descender.life.alive then
			emission.emitTaggedDescendants(descender.instance, descender:EmitRespawnedTag())

			if descender:ToggleConnectedParts() then
				for _, connected in base:GetConnectedParts(true) do
					toggle.toggleInstance(true, connected)
				end
			else
				toggle.toggleInstance(true, base)
			end

			align.MaxAxesForce = oldForce
			align.MaxVelocity = oldVelocity

			descender:Active(false)
		end
	end))
end

return Descender
