const activation = require "@libs/activation"
const Attribute = require "@libs/attributes/Attribute"
const character = require "@libs/character"
const properties = require "@libs/properties"
const std = require "@libs/std"

const Tripper = std.Mechanic {
	emoji = "🧀",
	name = "Tripper",
	description = "When activated, trips the player by making them sit down.",
	instanceType = std.isA.BasePart(),

	Cooldown = std.Attribute("Cooldown", std.gt.positiveNumber, 0),
	StunDuration = std.Attribute("StunDuration", std.gt.positiveNumber, 0),

	std.AttributeSection "Activation",
	Activation = activation.useAttributes(),
}

export type TripperMechanic = std.Mechanic<typeof(Tripper)>

function Tripper.onActivate(self: typeof(Tripper), tripper: TripperMechanic)
	const humanoid = character.getMaybeHumanoid()
	if humanoid then
		const stunDuration = tripper:StunDuration()
		const property = if stunDuration > 0 then "PlatformStand" else "Sit"
		if properties.getUnsafe(humanoid, property) then return end

		self.Activation.Enabled(tripper, false)
		properties.setUnsafe(humanoid, property, true)
		tripper.life:delay(
			stunDuration + tripper:Cooldown(),
			Attribute.set :: any,
			self.Activation.Enabled,
			tripper,
			true
		)

		if property == "PlatformStand" then
			humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
			tripper.life:delay(stunDuration, properties.setUnsafe, humanoid, property, false)
			tripper.life:delay(stunDuration, humanoid.SetStateEnabled, humanoid, Enum.HumanoidStateType.Jumping, true)
		end
	end
end

return Tripper
