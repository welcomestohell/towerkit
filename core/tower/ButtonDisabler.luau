const Button = require "@core/tower/Button"
const activation = require "@libs/activation"
const std = require "@libs/std"

const ButtonDisabler = std.Mechanic {
	emoji = "🕹️",
	name = "ButtonDisabler",
	description = "When activated, deactivates all active Buttons matching it's Group.",
	instanceType = std.isA.Instance(),

	Cooldown = std.Attribute("Cooldown", std.gt.positiveNumber, 0),
	Group = std.Attribute("Group", std.gt.tag, ""),

	std.AttributeSection "Activation",
	Activation = activation.useAttributes(),
}
export type ButtonDisablerMechanic = std.Mechanic<typeof(ButtonDisabler)>

-- Investigate: Should we add disabling individual buttons?
function ButtonDisabler.onActivate(self: typeof(ButtonDisabler), mechanic: ButtonDisablerMechanic, level: std.Level)
	self.Activation.Enabled(mechanic, false)
	const group = mechanic:Group()
	for _, button: Button.ButtonMechanic in level:getMechanics(Button) do
		if button:Group() == group then button:Active(false) end
	end
	task.wait(mechanic:Cooldown())
	self.Activation.Enabled(mechanic, true)
end

return ButtonDisabler
