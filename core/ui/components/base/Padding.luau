local Fluid = require "@roblox_packages/Fluid"
const Liquid = require "@roblox_packages/Liquid"

const ZERO_UDIM = UDim.new()

local function Padding(props: {
	name: Fluid.UsedAs<string>?,

	all: Fluid.UsedAs<UDim>?,
	horizontal: Fluid.UsedAs<UDim>?,
	vertical: Fluid.UsedAs<UDim>?,
	top: Fluid.UsedAs<UDim>?,
	bottom: Fluid.UsedAs<UDim>?,
	left: Fluid.UsedAs<UDim>?,
	right: Fluid.UsedAs<UDim>?,
})
	return Fluid.create "UIPadding" {
		Name = props.name or "Padding",

		PaddingTop = Liquid.useDissolved(function(read: Liquid.Read)
			return read<<UDim>>(props.top or props.vertical or props.all or ZERO_UDIM)
		end),
		PaddingBottom = Liquid.useDissolved(function(read: Liquid.Read)
			return read<<UDim>>(props.bottom or props.vertical or props.all or ZERO_UDIM)
		end),
		PaddingLeft = Liquid.useDissolved(function(read: Liquid.Read)
			return read<<UDim>>(props.left or props.horizontal or props.all or ZERO_UDIM)
		end),
		PaddingRight = Liquid.useDissolved(function(read: Liquid.Read)
			return read<<UDim>>(props.right or props.horizontal or props.all or ZERO_UDIM)
		end),
	}
end

return Padding
