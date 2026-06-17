const assets = require "@core/assets"
const Fluid = require "@roblox_packages/Fluid"
const Liquid = require "@roblox_packages/Liquid"
const NumberSpinner = require "@core/ui/components/base/NumberSpinner"
const Oklab = require "@libs/vendor/Oklab"
const Padding = require "@core/ui/components/base/Padding"
const Text = require "@core/ui/components/base/Text"

-- TODO: hoursHidden, secondsHidden, millisecondsHidden
export type TimerProps = {
	name: Fluid.UsedAs<string>?,
	position: Fluid.UsedAs<UDim2>?,
	anchorPoint: Fluid.UsedAs<Vector2>?,
	size: Fluid.UsedAs<UDim2>?,
	automaticSize: Fluid.UsedAs<Enum.AutomaticSize>?,
	layoutOrder: Fluid.UsedAs<number>?,
	zIndex: Fluid.UsedAs<number>?,

	icon: Fluid.UsedAs<string>?,
	color: Fluid.UsedAs<Color3>?,
	count: Fluid.UsedAs<number>?,
	valueSeconds: Fluid.UsedAs<number>,
	totalSeconds: Fluid.UsedAs<number>?,
	visible: Fluid.UsedAs<boolean>?,
}

const function Timer(props: TimerProps)
	const rem = Liquid.useRem()
	const nextOrder = Liquid.useNextOrder()

	const color = props.color or Color3.new(1, 1, 1)
	const function colorLch()
		return Oklab.color3ToOklch(Fluid.read(color))
	end

	const function colorLightness()
		return math.clamp(colorLch().X, 2 / 3, 1)
	end
	const function colorChroma()
		return math.clamp(colorLch().Y * 1.5, 0, 0.2)
	end

	const function baseColor()
		return Oklab.oklchToColor3(Vector3.new(colorLightness(), colorChroma(), colorLch().Z))
	end

	const function darkColor()
		return Oklab.oklchToColor3(Vector3.new(colorLightness() * 0.7, colorChroma(), colorLch().Z))
	end

	const function progressColor()
		return Oklab.oklchToColor3(Vector3.new(colorLightness() * 1.5, colorChroma(), colorLch().Z))
	end

	const function lightColor()
		return Oklab.oklchToColor3(Vector3.new(colorLightness() * 1.25, colorChroma(), colorLch().Z))
	end

	const function minutes()
		return Fluid.read(props.valueSeconds) // 60
	end
	const function seconds()
		return Fluid.read(props.valueSeconds) % 60
	end
	const function milliseconds()
		return Fluid.read(props.valueSeconds) * 100 % 100
	end

	const digitSize = rem:intoUdim2(4, 4)
	const digitTextSize = rem:intoPx(5)
	const millisecondsDigitSize = rem:intoPx(3)

	const contentAbsoluteSize = Fluid.source(Vector2.zero)
	const scale = Fluid.spring(Liquid.useToggled(props.visible, 1, 0), 15, 2 / 3)

	return Fluid.create "CanvasGroup" {
		Name = props.name or "Timer",

		Position = props.position,
		AnchorPoint = props.anchorPoint,
		Size = props.size or function()
			const contentAbsoluteSize = contentAbsoluteSize()
			const padding = rem:px(0.5)
			return UDim2.fromOffset(contentAbsoluteSize.X + padding, contentAbsoluteSize.Y + padding)
		end,
		AutomaticSize = props.automaticSize or Enum.AutomaticSize.None,
		LayoutOrder = props.layoutOrder,
		ZIndex = props.zIndex,

		Fluid.create "UICorner" { CornerRadius = rem:intoUdim(0.75) },
		BackgroundColor3 = Liquid.useToggled<<Color3>>(props.visible, progressColor, darkColor),
		ClipsDescendants = true,

		GroupTransparency = Fluid.spring(Liquid.useToggled(props.visible, 0, 1), 30, 1),
		Visible = function()
			return scale() >= 0.01
		end,
		Fluid.create "UIScale" { Scale = scale },

		Liquid.useShow(props.totalSeconds, Fluid.untrack :: any, function()
			const totalSeconds = props.totalSeconds :: Fluid.UsedAs<number>

			const function progress()
				return (Fluid.read(totalSeconds) - Fluid.read(props.valueSeconds)) / Fluid.read(totalSeconds)
			end

			const function isHalfway()
				return progress() >= 0.5
			end

			return {
				-- First 50%
				Fluid.create "ImageLabel" {
					BackgroundTransparency = 1,
					Position = UDim2.fromScale(0.5, 0.5),
					AnchorPoint = Vector2.new(0.5, 0.5),
					Size = UDim2.fromScale(2, 2),
					SizeConstraint = Enum.SizeConstraint.RelativeXX,
					Image = assets.ui.fillRight,
					ImageColor3 = Liquid.useToggled<<Color3>>(isHalfway, progressColor, darkColor),
					Rotation = function()
						const p = progress()
						return if isHalfway() then 0 else p * 360
					end,
					ZIndex = 0,
				},
				-- Last 50%
				Fluid.create "ImageLabel" {
					BackgroundTransparency = 1,
					Position = UDim2.fromScale(0.5, 0.5),
					AnchorPoint = Vector2.new(0.5, 0.5),
					Size = UDim2.fromScale(2, 2),
					SizeConstraint = Enum.SizeConstraint.RelativeXX,
					Image = assets.ui.fillLeft,
					ImageColor3 = darkColor,
					Rotation = function()
						const p = progress()
						return if p <= 0.5 then 0 else (p - 0.5) * 360
					end,
					ZIndex = -1,
				},
			}
		end),

		Fluid.create "Frame" {
			Name = "Content",
			Size = UDim2.new(),
			AutomaticSize = Enum.AutomaticSize.XY,
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.new(1, 1, 1),

			Fluid.create "UIGradient" {
				Color = function()
					return ColorSequence.new(lightColor(), baseColor())
				end,
				Rotation = 90,
			},

			Liquid.outProperty("AbsoluteSize", contentAbsoluteSize),

			Fluid.create "UIListLayout" {
				FillDirection = Enum.FillDirection.Horizontal,
				SortOrder = Enum.SortOrder.LayoutOrder,
				VerticalAlignment = Enum.VerticalAlignment.Bottom,
			},

			Fluid.create "UICorner" { CornerRadius = rem:intoUdim(0.5) },
			Padding { horizontal = rem:intoUdim(1), bottom = rem:intoUdim(0.125) },

			-- useShow(
			-- 	props.icon,
			-- 	Fluid.untrack :: any,
			-- 	function()
			-- 		return Fluid.create "Frame" {
			-- 			Name = "Icon",
			-- 			BackgroundTransparency = 1,
			-- 			Size = rem:intoUdim2(4, 4),

			-- 			Padding { all = rem:intoUdim(0.25) },
			-- 			Fluid.create "ImageLabel" {
			-- 				BackgroundTransparency = 1,
			-- 				Position = UDim2.fromScale(0.5, 0.5),
			-- 				AnchorPoint = Vector2.new(0.5, 0.5),
			-- 				Size = UDim2.fromScale(1, 1),
			-- 				Image = props.icon,
			-- 				ImageColor3 = darkColor,
			-- 			},
			-- 		}
			-- 	end
			-- ),

			NumberSpinner {
				name = "MinutesSpinner",
				value = minutes,
				numDigits = 2,

				size = digitSize,
				textSize = digitTextSize,
				textColor = darkColor,
				fontWeight = Enum.FontWeight.SemiBold,

				layoutOrder = nextOrder(),
			},

			Text {
				name = "Colon",
				text = ":",
				textSize = millisecondsDigitSize,
				textColor = darkColor,
				font = Font.fromEnum(Enum.Font.Gotham),
				fontWeight = Enum.FontWeight.SemiBold,

				layoutOrder = nextOrder(),

				Padding { bottom = rem:intoUdim(1 / 3) },
			},

			NumberSpinner {
				name = "SecondsSpinner",
				value = seconds,
				numDigits = 2,

				size = digitSize,
				textSize = digitTextSize,
				textColor = darkColor,
				fontWeight = Enum.FontWeight.SemiBold,

				layoutOrder = nextOrder(),
			},

			Text {
				name = "MillisecondsSpinner",
				text = function()
					return string.format("%02i", milliseconds())
				end,
				textSize = millisecondsDigitSize,
				textColor = darkColor,

				layoutOrder = nextOrder(),
			},
		},
	}
end

return Timer
