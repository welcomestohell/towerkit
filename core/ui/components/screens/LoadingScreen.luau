const Fluid = require "@roblox_packages/Fluid"
const Padding = require "@core/ui/components/base/Padding"
const Text = require "@core/ui/components/base/Text"
const assets = require "@core/assets"
const Liquid = require "@roblox_packages/Liquid"

const function LoadingScreen(props: {
	label: Fluid.UsedAs<string>,
	title: Fluid.UsedAs<string>,
	imageId: Fluid.UsedAs<string>?,
	name: Fluid.UsedAs<string>?,
	zIndex: Fluid.UsedAs<number>?,
	visible: Fluid.UsedAs<boolean>?,
})
	local rem = Liquid.useRem()
	local nextOrder = Liquid.useNextOrder()

	local function transparency()
		return Fluid.read(props.visible) and 0 or 1
	end

	local function imageTransparency()
		return Fluid.read(props.visible) and 2 / 3 or 1
	end

	local labelVisible = Liquid.useDelay(0.1, props.visible)
	local function labelTransparency()
		return labelVisible() and 0 or 1
	end

	local titleVisible = Liquid.useDelay(0.05, props.visible)
	local function titleTransparency()
		return titleVisible() and 0 or 1
	end

	return Fluid.create "ImageLabel" {
		Name = props.name or "LoadingScreen",
		BackgroundColor3 = Color3.new(0, 0, 0),
		Size = UDim2.fromScale(1, 1),
		ZIndex = props.zIndex,

		Image = props.imageId,
		ScaleType = Enum.ScaleType.Crop,
		ImageTransparency = Fluid.spring(imageTransparency, 5, 0.5),

		Fluid.create "Frame" {
			Name = "Gradient",
			BackgroundColor3 = Color3.new(0, 0, 0),
			Size = UDim2.fromScale(1, 1),

			Fluid.create "UIGradient" {
				Transparency = NumberSequence.new(0, 1),
				Rotation = 90,
			},
		},

		Fluid.create "Frame" {
			Name = "Bottom",
			BackgroundTransparency = 1,

			Position = UDim2.fromScale(0, 1),
			AnchorPoint = Vector2.new(0, 1),
			Size = UDim2.new(),
			AutomaticSize = Enum.AutomaticSize.XY,

			Padding { all = rem:intoUdim(2) },

			-- Not using WTHLogo since this needs to be replicated across
			-- teleports, which would desync any logo animations
			Fluid.create "ImageLabel" {
				Name = "Logo",
				BackgroundTransparency = 1,
				Image = assets.branding.wth.fullFit,
				ScaleType = Enum.ScaleType.Fit,
				Size = rem:intoUdim2(10, 6),
				ImageTransparency = Fluid.spring(transparency, 15, 0.5),
				Position = Fluid.spring(
					Liquid.useToggled<<UDim2>>(props.visible, UDim2.new(), rem:intoUdim2(-0.5, 0)),
					15,
					0.5
				),
			},

			Text {
				name = "Label",
				layoutOrder = nextOrder(),
				text = props.label,
				textSize = rem:intoPx(2),
				transparency = Fluid.spring(labelTransparency, 15, 0.5),
				position = Fluid.spring(
					Liquid.useToggled<<UDim2>>(labelVisible, rem:intoUdim2(10.5, 0), rem:intoUdim2(10, 0)),
					15,
					0.5
				),

				-- I have no clue what the fucl im smoking
				-- Fluid.create "Frame" {
				-- 	Name = "Dots",
				-- 	Position = UDim2.fromScale(1, 0),
				-- 	AutomaticSize = Enum.AutomaticSize.X,
				-- 	Size = UDim2.fromScale(0, 0),

				-- 	forRange<<any>>(function(index)
				-- 		local position, positionMotion = useMotion(UDim2.new(rem:px(index), 0))
				-- 		positionMotion:tween(rem:udim2(index, -0.25), { reverses = true, repeats = math.huge })

				-- 		return Text {
				-- 			name = "Label",
				-- 			layoutOrder = nextOrder(),
				-- 			text = ".",
				-- 			textSize = rem:intoPx(1),
				-- 			position = position,
				-- 			automaticSize = Enum.AutomaticSize.None,
				-- 		}
				-- 	end, 1, 3),
				-- },
			},

			Text {
				name = "Title",
				layoutOrder = nextOrder(),
				fontWeight = Enum.FontWeight.Bold,
				text = props.title,
				textSize = rem:intoPx(6),
				transparency = Fluid.spring(titleTransparency, 15, 0.5),
				position = Fluid.spring(
					Liquid.useToggled<<UDim2>>(titleVisible, rem:intoUdim2(10.5, 1.5), rem:intoUdim2(10, 1.5)),
					15,
					0.5
				),

				Padding { vertical = rem:intoUdim(-0.5) },
			},
		},
	}
end

return LoadingScreen
