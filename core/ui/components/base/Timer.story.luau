const Timer = require "@core/ui/components/base/Timer"
const timers = require "@libs/timers"
const Liquid = require "@roblox_packages/Liquid"

const DURATION_SECONDS = 120
const SPEED_UP = 1

return Liquid.createFluidStory {
	controls = {
		color = Color3.new(1, 0, 0.5),
		count = 1,
		visible = true,
	},
	render = function(props)
		local valueSeconds, valueMotion = Liquid.useMotion(DURATION_SECONDS)
		valueMotion:tween(0, { duration = DURATION_SECONDS / SPEED_UP })
		valueMotion:onComplete(function()
			valueMotion:setPosition(DURATION_SECONDS)
			valueMotion:tween(0, { duration = DURATION_SECONDS / SPEED_UP })
		end)

		return Timer {
			icon = timers.BUTTON_ICON,
			color = props.controls.color,
			count = 1,
			valueSeconds = valueSeconds,
			totalSeconds = DURATION_SECONDS,
			position = UDim2.fromScale(0.5, 0.5),
			anchorPoint = Vector2.new(0.5, 0.5),
			visible = props.controls.visible,
		}
	end,
}
