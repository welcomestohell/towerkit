local std = require("@libs/std")

local ScrollingImage = std.Mechanic({})
export type ScrollingImageMechanic = std.Mechanic<typeof(ScrollingImage)>
ScrollingImage.instanceTag = "ScrollingImage"
ScrollingImage.instanceType = std.isA.ImageLabel()
ScrollingImage.debuggerEmoji = "🏁"

ScrollingImage.Speed = ScrollingImage:attribute("Speed", std.gt.UDim2(), UDim2.new())
ScrollingImage.BasePosition = ScrollingImage:attribute("BasePosition", std.gt.UDim2(), UDim2.new())
ScrollingImage.Synchronized = ScrollingImage:attribute("Synchronized", std.gt.boolean(), true)
ScrollingImage.SetDefaults = ScrollingImage:attribute("SetDefaults", std.gt.boolean(), true)

function ScrollingImage:onStart(image: ScrollingImageMechanic)
	if image:SetDefaults() then
		image.instance.AnchorPoint = Vector2.zero
		image.instance.ScaleType = Enum.ScaleType.Tile

		local tileSize = image.instance.TileSize
		image.instance.Size = UDim2.new(
			1 + tileSize.Width.Scale * 2,
			tileSize.Width.Offset * 2,
			1 + tileSize.Height.Scale * 2,
			tileSize.Width.Offset * 2
		)

		local offset = image:BasePosition()
		if not offset then
			image.BasePosition:set(image, image.instance.Position)
		else
			image.instance.Position = offset
		end
	end
end

function ScrollingImage:onPreRender(deltaTime: number, level: std.Level)
	local lifetime = level:getLifetime()
	for _, image in level:getMechanics(ScrollingImage) do
		if not image:Enabled() then
			continue
		end

		local instance = image.instance
		local absoluteSize = instance.AbsoluteSize

		local speed = image:Speed()
		local base = image:BasePosition() or instance.Position

		local tileSize = instance.TileSize
		local tileSizeScale = Vector2.new(tileSize.X.Scale, tileSize.Y.Scale)
		local tileSizeOffset = Vector2.new(tileSize.X.Offset, tileSize.Y.Offset)
		local absoluteTileSize = absoluteSize * tileSizeScale + tileSizeOffset

		local baseAbsolute = absoluteSize * Vector2.new(base.X.Scale, base.Y.Scale)
			+ Vector2.new(base.X.Offset, base.Y.Offset)

		local delta = absoluteSize * Vector2.new(speed.X.Scale, speed.Y.Scale)
			+ Vector2.new(speed.X.Offset, speed.Y.Offset)

		local absolutePosition = if image:Synchronized()
			then baseAbsolute + delta * lifetime
			else baseAbsolute + delta * deltaTime

		absolutePosition = Vector2.new(
			((absolutePosition.X + absoluteTileSize.X) % absoluteTileSize.X) - absoluteTileSize.X,
			((absolutePosition.Y + absoluteTileSize.Y) % absoluteTileSize.Y) - absoluteTileSize.Y
		)

		instance.Position = UDim2.fromOffset(absolutePosition.X, absolutePosition.Y)

		if not image:Synchronized() then
			image.BasePosition:set(image, instance.Position)
		end
	end
end

return ScrollingImage
