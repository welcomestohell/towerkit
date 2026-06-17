local Fluid = require "@roblox_packages/Fluid"
const Liquid = require "@roblox_packages/Liquid"

local function Text(props: {
	name: Fluid.UsedAs<string>?,
	position: Fluid.UsedAs<UDim2>?,
	anchorPoint: Fluid.UsedAs<Vector2>?,
	size: Fluid.UsedAs<UDim2>?,
	automaticSize: Fluid.UsedAs<Enum.AutomaticSize>?,
	layoutOrder: Fluid.UsedAs<number>?,
	zIndex: Fluid.UsedAs<number>?,

	transparency: Fluid.UsedAs<number>?,
	lineHeight: Fluid.UsedAs<number>?,

	text: Fluid.UsedAs<string>?,
	textSize: Fluid.UsedAs<number>?,
	textScaled: Fluid.UsedAs<boolean>?,
	textColor: Fluid.UsedAs<Color3>?,
	textRich: Fluid.UsedAs<boolean>?,
	textWraps: Fluid.UsedAs<boolean>?,
	textTruncate: Fluid.UsedAs<Enum.TextTruncate>?,
	font: Fluid.UsedAs<Font>?,
	fontWeight: Fluid.UsedAs<Enum.FontWeight>?,
	fontStyle: Fluid.UsedAs<Enum.FontStyle>?,
	horizontalAlign: Fluid.UsedAs<Enum.TextXAlignment>?,
	verticalAlign: Fluid.UsedAs<Enum.TextYAlignment>?,
	maxVisibleGraphemes: Fluid.UsedAs<number>?,

	[number]: Fluid.UsedAs<Instance>,
})
	return Fluid.create "TextLabel" {
		Name = props.name or props.text or "Text",
		BackgroundTransparency = 1,

		Position = props.position,
		AnchorPoint = props.anchorPoint,
		Size = props.size or UDim2.new(0, 0),
		AutomaticSize = props.automaticSize or Enum.AutomaticSize.XY,
		LayoutOrder = props.layoutOrder,
		ZIndex = props.zIndex,

		TextTransparency = props.transparency,
		LineHeight = props.lineHeight,

		Text = props.text,
		TextSize = props.textSize,
		TextScaled = props.textScaled,
		TextWrapped = props.textWraps,
		TextTruncate = props.textTruncate,
		TextXAlignment = props.horizontalAlign,
		TextYAlignment = props.verticalAlign,
		MaxVisibleGraphemes = props.maxVisibleGraphemes,

		TextColor3 = props.textColor or Color3.new(1, 1, 1),
		RichText = if props.textRich == nil then true else props.textRich,
		FontFace = Liquid.useDissolved<<Font>>(function(read: Liquid.Read)
			return Font.new(
				read<<Font>>(props.font or Font.fromEnum(Enum.Font.TitilliumWeb)).Family,
				read<<Enum.FontWeight>>(props.fontWeight or Enum.FontWeight.Regular),
				read<<Enum.FontStyle>>(props.fontStyle or Enum.FontStyle.Normal)
			)
		end),

		table.unpack(props),
	}
end

return Text
