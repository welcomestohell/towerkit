const Timer = require "@core/ui/components/base/Timer"
const timers = require "@libs/timers"
const Fluid = require "@roblox_packages/Fluid"
const Liquid = require "@roblox_packages/Liquid"

const function TimerStack(props: {
	name: Fluid.UsedAs<string>?,
	position: Fluid.UsedAs<UDim2>?,
	anchorPoint: Fluid.UsedAs<Vector2>?,
	size: Fluid.UsedAs<UDim2>?,
	automaticSize: Fluid.UsedAs<Enum.AutomaticSize>?,
	layoutOrder: Fluid.UsedAs<number>?,
	zIndex: Fluid.UsedAs<number>?,

	timers: Fluid.UsedAs<{ [string]: timers.Timer }>,
})
	const rem = Liquid.useRem()
	const clock = Liquid.useOsClock()

	return Fluid.create "Frame" {
		Name = props.name or "TimerStack",

		Position = props.position,
		AnchorPoint = props.anchorPoint,
		Size = props.size or UDim2.new(0, 0),
		AutomaticSize = props.automaticSize or Enum.AutomaticSize.XY,
		LayoutOrder = props.layoutOrder,
		ZIndex = props.zIndex,
		BackgroundTransparency = 1,

		Fluid.create "UIListLayout" {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Top,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = rem:intoUdim(0.5),
		},

		Liquid.forPairs(props.timers, function(key, timer: timers.Timer): any
			const firstTimestamp = timer.timestamps[1]
			const lastTimestamp = timer.timestamps[#timer.timestamps]

			const endTimestamp = lastTimestamp + timer.duration

			const props: Timer.TimerProps = {
				valueSeconds = function()
					return math.max(endTimestamp - clock(), 0)
				end,
				totalSeconds = timer.duration,
				icon = timer.icon,
				color = timer.color,
				count = #timer.timestamps,
				visible = function()
					return clock() - firstTimestamp >= 0 and endTimestamp - clock() >= 0.05
				end,
				layoutOrder = firstTimestamp * 1000,
			}

			return key, Fluid.untrack(Timer, props)
		end),
	}
end

return TimerStack
