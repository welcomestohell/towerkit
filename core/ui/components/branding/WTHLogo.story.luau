local WTHLogo = require "./WTHLogo"
const Liquid = require "@roblox_packages/Liquid"

return Liquid.createFluidStory {
	controls = {
		visible = true,
	},
	render = function(props)
		return WTHLogo {
			visible = props.controls.visible,
			anchorPoint = Vector2.new(0.5, 0.5),
			position = UDim2.fromScale(0.5, 0.5),
		}
	end,
}
