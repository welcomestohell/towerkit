const Fluid = require "@roblox_packages/Fluid"
const assets = require "@core/assets"
const Liquid = require "@roblox_packages/Liquid"

const function FireworksLogo(props: {
	visible: Fluid.UsedAs<boolean>,
	transparency: Fluid.UsedAs<number>?,

	name: Fluid.UsedAs<string>?,
	size: Fluid.UsedAs<UDim2>?,
	color: Fluid.UsedAs<Color3>?,

	anchorPoint: Fluid.UsedAs<Vector2>?,
	position: Fluid.UsedAs<UDim2>?,
	layoutOrder: Fluid.UsedAs<number>?,
	zIndex: Fluid.UsedAs<number>?,
})
	local rem = Liquid.useRem()

	local progress = Liquid.useToggled(props.visible, 0, 1)
	local transparency = Fluid.spring(function()
		return Fluid.read(progress) * math.map(Fluid.read(props.transparency or 0), 0, 1, 1, 0)
	end, 10, 0.5)
	local sparkSize = Liquid.useToggled(props.visible, UDim2.fromScale(14 / 74, 14 / 24), UDim2.fromScale(0, 0))
	local topPosition =
		Fluid.spring(Liquid.useToggled(props.visible, UDim2.fromScale(0, 0), UDim2.fromScale(0.025, 0)), 10, 1 / 3)
	local bottomPosition =
		Fluid.spring(Liquid.useToggled(props.visible, UDim2.fromScale(0, 0), UDim2.fromScale(0.025, 0)), 10, 1 / 3)

	local sparkRotation = Fluid.source(0)
	Fluid.effect(function()
		Fluid.read(props.visible)
		Fluid.untrack(function()
			return sparkRotation(sparkRotation() + 3)
		end)
	end)

	local function bottomRightPosition()
		return UDim2.fromScale(-Fluid.read(bottomPosition).X.Scale, 0)
	end

	return Fluid.create "Frame" {
		Name = props.name or "FireworksSpark",
		BackgroundTransparency = 1,
		ZIndex = props.zIndex,

		AnchorPoint = props.anchorPoint,
		Position = props.position,
		LayoutOrder = props.layoutOrder,
		Size = props.size or function()
			return UDim2.fromOffset(rem(24), rem(24))
		end,

		Fluid.create "UIAspectRatioConstraint" {
			AspectRatio = 74 / 24,
		},

		Fluid.create "ImageLabel" {
			Name = "Top",
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Position = topPosition,

			Image = assets.branding.fireworks.wordmarkTop,
			ImageColor3 = props.color,
			ImageTransparency = transparency,
		},

		Fluid.create "ImageLabel" {
			Name = "BottomLeft",
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Position = bottomPosition,

			Image = assets.branding.fireworks.wordmarkBottomLeft,
			ImageColor3 = props.color,
			ImageTransparency = transparency,
		},

		Fluid.create "ImageLabel" {
			Name = "BottomRight",
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Position = bottomRightPosition,

			Image = assets.branding.fireworks.wordmarkBottomRight,
			ImageColor3 = props.color,
			ImageTransparency = transparency,
		},

		Fluid.create "Frame" {
			Name = "Spark",
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 0.5),
			-- Trust me bro
			Position = UDim2.fromScale(35.25 / 74 + 7 / 74, 10 / 24 + 7 / 24),
			Size = Fluid.spring(sparkSize, 10, 2 / 3),

			Fluid.create "ImageLabel" {
				BackgroundTransparency = 1,

				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(1, 1),

				Image = assets.branding.fireworks.fireworks8,
				ImageColor3 = props.color,
				ImageTransparency = transparency,

				Rotation = Fluid.spring(function()
					return sparkRotation() * -60 * 2
				end, 20, 1),
			},

			Fluid.create "ImageLabel" {
				BackgroundTransparency = 1,

				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(1, 1),

				Image = assets.branding.fireworks.fireworksX,
				ImageColor3 = props.color,
				ImageTransparency = transparency,

				Rotation = Fluid.spring(function()
					return sparkRotation() * -60
				end, 20, 1),
			},
		},
	}
end

return FireworksLogo
