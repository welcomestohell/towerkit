const TweenService = game:GetService "TweenService"

const std = require "@libs/std"
const tweens = require "@libs/tweens"

const Spinner = std.Mechanic {
	emoji = "🌀",
	name = "Spinner",
	description = "Continously spins within it's axes.",
	instanceType = std.gt.instanceTree {
		Center = std.isA.BasePart(),
		Base = std.isA.BasePart(),
	},

	Enabled = std.Attribute("Enabled", std.gt.boolean(), true),
	Inverted = std.Attribute("Inverted", std.gt.boolean(), false),
	Angle = std.Attribute("Angle", std.gt.NumberRange, NumberRange.new(0, 360)),
	Offset = std.Attribute("Offset", std.gt.Vector3(), Vector3.zero),

	std.AttributeSection "Timing",
	Synchronized = std.Attribute("Synchronized", std.gt.boolean(), true),
	TimeOffset = std.Attribute("TimeOffset", std.gt.positiveNumber, 0),
	Elapsed = std.Attribute("Elapsed", std.gt.number(), 0),

	std.AttributeSection "Axes",
	XEnabled = std.Attribute("XEnabled", std.gt.boolean(), false),
	YEnabled = std.Attribute("YEnabled", std.gt.boolean(), true),
	ZEnabled = std.Attribute("ZEnabled", std.gt.boolean(), false),

	std.AttributeSection "Tween",
	Tween = tweens.useAttributes(),
}

export type SpinnerMechanic = std.Mechanic<typeof(Spinner)>

function Spinner.onStart(self: typeof(Spinner), spinner: SpinnerMechanic)
	spinner.Synchronized:onBind(spinner, function()
		spinner:Elapsed(0)
	end)
end

function Spinner.onPreSimulation(self: typeof(Spinner), deltaTime: number, level: std.Level)
	const lifetime = level:getLifetime()
	for _, spinner: SpinnerMechanic in level:getMechanics(self) do
		if not spinner:Enabled() then continue end

		local elapsed = if spinner:Synchronized()
			then lifetime
			else spinner:Elapsed(spinner:Elapsed() :: number + deltaTime)
		elapsed += spinner:TimeOffset()

		const duration = self.Tween.Duration(spinner)
		local cycleProgress = (elapsed % duration) / duration
		if spinner:Inverted() then cycleProgress = math.map(cycleProgress, 0, 1, 1, 0) end
		const angle = spinner:Angle() :: NumberRange
		const alpha = TweenService:GetValue(cycleProgress, self.Tween.Style(spinner), self.Tween.Direction(spinner))
		const axisRotation = math.rad(math.map(alpha, 0, 1, angle.Min, angle.Max))
		spinner.instance.Base.CFrame = spinner.instance.Center.CFrame
			* CFrame.Angles(
				spinner:XEnabled() and axisRotation or 0,
				spinner:YEnabled() and axisRotation or 0,
				spinner:ZEnabled() and axisRotation or 0
			)
			* CFrame.new(spinner:Offset())
	end
end

return Spinner
