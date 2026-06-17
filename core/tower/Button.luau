const logger = require "@core/shared/logger"
const activation = require "@libs/activation"
const Attribute = require "@libs/attributes/Attribute"
const press = require "@libs/press"
const std = require "@libs/std"
const timers = require "@libs/timers"
const toggle = require "@libs/toggle"

const Button = std.Mechanic {
	emoji = "🖲️",
	name = "Button",
	description = "When activated, toggles it's Group for the specified duration.",
	instanceType = std.gt.union(std.isA.BasePart(), std.isA.Model()),

	activeGroups = std.LevelState<<{ [string]: true }>> {},

	Active = std.Attribute("Active", std.gt.boolean(), true),
	Cooldown = std.Attribute("Cooldown", std.gt.positiveNumber, 0.5),
	Duration = std.Attribute("Duration", std.gt.number(), 5),
	Group = std.Attribute("Group", std.gt.tag, ""),

	std.AttributeSection "Timer",
	TimerEnabled = std.Attribute("TimerEnabled", std.gt.boolean(), true),
	HoursHidden = std.Attribute("HoursHidden", std.gt.boolean(), false),
	MinutesHidden = std.Attribute("MinutesHidden", std.gt.boolean(), false),
	MillisecondsHidden = std.Attribute("MillisecondsHidden", std.gt.boolean(), false),

	std.AttributeSection "Activation",
	Activation = activation.useAttributes(),

	std.AttributeSection "Press",
	Press = press.useAttributes(),
}

export type ButtonMechanic = std.Mechanic<typeof(Button)>

function Button.handleGroup(self: typeof(Button), level: std.Level, group: string)
	if group == "" then return end

	local activeGroups = self.activeGroups:get(level)
	local wasActive = activeGroups[group] or false

	local shouldBeActive = false
	for _, other: ButtonMechanic in level:getMechanics(self) do
		if other:Group() == group and other:Active() then
			shouldBeActive = true
			break
		end
	end

	if shouldBeActive ~= wasActive then
		activeGroups[group] = if shouldBeActive then true else nil
		logger:Debug(group, "->", shouldBeActive)

		for _, instance in level:getGroupedInstances(group) do
			toggle.toggleInstance(shouldBeActive, instance)
		end
	end
end

function Button.onInit(self: typeof(Button), level: std.Level)
	self.activeGroups:set(level, {} :: typeof(self.activeGroups:get(level)))
end

function Button.getActivationInstances(self: typeof(Button), button: ButtonMechanic)
	return if button.instance:IsA "BasePart"
		then button.instance :: BasePart
		else button.instance.PrimaryPart or button.instance:FindFirstChild "Button" :: BasePart
end

function Button.onActivate(self: typeof(Button), button: ButtonMechanic, level: std.Level)
	if button:Active() then return end

	local buttonPart: BasePart = self:getActivationInstances(button)
	if not buttonPart then
		logger:Warn("Missing primary part on button", button.instance:GetFullName())
		return
	end

	self.Activation.Enabled(button, false)
	button:Active(true)

	const group = button:Group()
	self:handleGroup(level, group)

	local deactivationLife = button.life:extend()
	deactivationLife:addMany(
		press.usePress {
			instance = buttonPart,
			instanceConfiguration = button.instanceConfiguration,
			attributes = self.Press,
		},
		function()
			button:Active(false)
			self:handleGroup(level, group)
			task.delay(button:Cooldown(), Attribute.set :: any, self.Activation.Enabled, button, true)
		end,
		self.Group:onChange(button, deactivationLife:wrapDestroy() :: (...any) -> ()),
		self.Active:onChange(button, function(value)
			if not value then deactivationLife:destroy() end
		end)
	)

	local duration = button:Duration()
	if duration > 0 then
		const key = `{level.name}_Button({group})`

		timers.increment(key, {
			color = buttonPart.Color,
			duration = duration,
			icon = timers.BUTTON_ICON,
		})

		deactivationLife:add(function()
			timers.decrement(key)
		end)
		deactivationLife:delay(duration, deactivationLife:wrapDestroy())
	end
end

return Button
