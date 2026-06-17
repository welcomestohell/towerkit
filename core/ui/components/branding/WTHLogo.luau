const Fluid = require "@roblox_packages/Fluid"
const assets = require "@core/assets"
const Liquid = require "@roblox_packages/Liquid"

const function Letter(props: {
	name: string,
	imageId: string,

	visible: Fluid.UsedAs<boolean>,
	transparency: Fluid.UsedAs<number>?,

	xShift: number,
	zIndex: number,
})
	local function progress()
		return Fluid.read(props.visible) and 0 or 1
	end

	local function size()
		local scale = 1 + Fluid.read(progress) / 20
		return UDim2.fromScale(scale, scale)
	end

	local function position()
		local transparency = Fluid.read(progress)
		return UDim2.fromScale(
			0.5 + math.map(transparency, 1, 0, 0.02, 0) * props.xShift,
			math.map(transparency, 1, 0, -0.09, 0)
		)
	end

	return Fluid.create "ImageLabel" {
		Name = props.name,
		ZIndex = props.zIndex,
		BackgroundTransparency = 1,

		Image = props.imageId,
		ImageTransparency = Fluid.spring(progress, 20, 2 / 3),

		AnchorPoint = Vector2.new(0.5, 0),
		Position = Fluid.spring(position, 20, 1 / 3),
		Size = Fluid.spring(size, 10, 1 / 3),
	}
end

local function WTHLogo(props: {
	visible: Fluid.UsedAs<boolean>,
	transparency: Fluid.UsedAs<number>?,

	name: Fluid.UsedAs<string>?,
	size: Fluid.UsedAs<UDim2>?,

	anchorPoint: Fluid.UsedAs<Vector2>?,
	position: Fluid.UsedAs<UDim2>?,
	layoutOrder: Fluid.UsedAs<number>?,
	zIndex: Fluid.UsedAs<number>?,
})
	local rem = Liquid.useRem()

	return Fluid.create "Frame" {
		Name = props.name or "WTHLogo",
		BackgroundTransparency = 1,
		ZIndex = props.zIndex,

		AnchorPoint = props.anchorPoint,
		Position = props.position,
		LayoutOrder = props.layoutOrder,
		Size = props.size or function()
			return UDim2.fromOffset(rem(24), rem(24))
		end,

		Fluid.create "UIAspectRatioConstraint" {},

		Letter {
			name = "W",
			imageId = assets.branding.wth.letterW,
			visible = Liquid.useDelay<<boolean>>(0, props.visible),
			transparency = props.transparency,
			xShift = -1,
			zIndex = 1,
		},

		Letter {
			name = "T",
			imageId = assets.branding.wth.letterT,
			visible = Liquid.useDelay<<boolean>>(0.1, props.visible),
			transparency = props.transparency,
			xShift = 0,
			zIndex = 2,
		},

		Letter {
			name = "H",
			imageId = assets.branding.wth.letterH,
			visible = Liquid.useDelay<<boolean>>(0.2, props.visible),
			transparency = props.transparency,
			xShift = 1,
			zIndex = 1,
		},
	}
end

return WTHLogo
