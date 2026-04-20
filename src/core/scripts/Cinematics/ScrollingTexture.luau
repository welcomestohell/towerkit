local std = require("@libs/std")

local ScrollingTexture = std.Mechanic({})
export type ScrollingTextureMechanic = std.Mechanic<typeof(ScrollingTexture)>
ScrollingTexture.basename = "ScrollingTexture"
ScrollingTexture.instanceType = std.isA.Texture()
ScrollingTexture.debuggerEmoji = "🏁"

ScrollingTexture.Enabled = ScrollingTexture:withEnabled()
ScrollingTexture.Speed = ScrollingTexture:attribute("Speed", std.gt.Vector2(), Vector2.zero)
ScrollingTexture.Offset = ScrollingTexture:attribute("Offset", std.gt.Vector2(), Vector2.zero)
ScrollingTexture.Synchronized = ScrollingTexture:attribute("Synchronized", std.gt.boolean(), true)
ScrollingTexture.LoopHorizontally = ScrollingTexture:attribute("LoopHorizontally", std.gt.boolean(), true)
ScrollingTexture.LoopVertically = ScrollingTexture:attribute("LoopVertically", std.gt.boolean(), true)
ScrollingTexture.SetDefaults = ScrollingTexture:attribute("SetDefaults", std.gt.boolean(), true)

function ScrollingTexture.onPreRender(self: typeof(ScrollingTexture), deltaTime: number, level: std.Level)
	local lifetime = level:getLifetime()

	for _, texture in level:getMechanics(self) do
		if not texture:Enabled() then
			continue
		end

		local speed = texture:Speed()
		local offset = texture:Offset()
		local newOffset = if texture:Synchronized()
			then offset + speed / Vector2.new(texture.instance.StudsPerTileU, texture.instance.StudsPerTileV) * lifetime
			else Vector2.new(texture.instance.OffsetStudsU, texture.instance.OffsetStudsV) + speed * deltaTime

		texture.instance.OffsetStudsU = if texture:LoopHorizontally()
			then newOffset.X % texture.instance.StudsPerTileU
			else newOffset.X

		texture.instance.OffsetStudsV = if texture:LoopVertically()
			then newOffset.Y % texture.instance.StudsPerTileV
			else newOffset.Y
	end
end

function ScrollingTexture.onStart(self: typeof(ScrollingTexture), texture: ScrollingTextureMechanic)
	local offset = self.Offset:peek(texture)
	if offset then
		texture.instance.OffsetStudsU = offset.X
		texture.instance.OffsetStudsV = offset.Y
	else
		texture:Offset(Vector2.new(texture.instance.OffsetStudsU, texture.instance.OffsetStudsV))
	end
end

return ScrollingTexture
