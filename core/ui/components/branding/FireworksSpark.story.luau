local FireworksSpark = require "./FireworksSpark"
const Liquid = require "@roblox_packages/Liquid"

return Liquid.createFluidStory {
	controls = {
		visible = true,
		color = Color3.fromHex "#FF004D",
	},
	render = function(props)
		return FireworksSpark {
			visible = props.controls.visible,
			color = props.controls.color,
			anchorPoint = Vector2.new(0.5, 0.5),
			position = UDim2.fromScale(0.5, 0.5),
		}
	end,
}
