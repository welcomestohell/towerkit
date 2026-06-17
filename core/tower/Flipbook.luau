local std = require "@libs/std"

local Flipbook = std.Mechanic {
	emoji = "🎞️",
	name = "Flipbook",
	instanceType = std.gt.union(std.isA.ImageLabel(), std.isA.Decal()),

	Enabled = std.Attribute("Enabled", std.gt.boolean(), true),
	GridSize = std.Attribute("GridSize", std.gt.Vector2(), Vector2.one),
	Mode = std.Attribute("Mode", std.gt.enumOf(Enum.ParticleFlipbookMode), Enum.ParticleFlipbookMode.Loop),
	SetDefaults = std.Attribute("SetDefaults", std.gt.boolean(), true),

	Framerate = std.Attribute("Framerate", std.gt.number(), 1),
	NumFrames = std.Attribute("NumFrames", std.gt.optional(std.gt.number()), nil),
	Index = std.Attribute("Index", std.gt.number(), 0),

	Synchronized = std.Attribute("Synchronized", std.gt.boolean(), false),
	Elapsed = std.Attribute("Elapsed", std.gt.number(), 0),
}

export type FlipbookMechanic = std.Mechanic<typeof(Flipbook)>

function Flipbook:onStart(flipbook: FlipbookMechanic)
	flipbook.GridSize:onBind(flipbook, function(gridSize: Vector2)
		if flipbook:SetDefaults() then
			if flipbook.instance.ClassName == "ImageLabel" then
				flipbook.instance.Size = UDim2.fromScale(gridSize.X, gridSize.Y)
			elseif flipbook.instance.ClassName == "Decal" then
				flipbook.instance.UVScale = Vector2.one / gridSize
			end
		end
	end)

	flipbook.Synchronized:onChange(flipbook, function()
		flipbook:Elapsed(0)
	end)
end

-- FIXME: PingPong desyncs :(
function Flipbook.onPreRender(self: typeof(Flipbook), deltaTime: number, level: std.Level)
	local lifetime = level:getLifetime()
	for _, flipbook: FlipbookMechanic in level:getMechanics(self) do
		if not flipbook:Enabled() then continue end

		local framerate = flipbook:Framerate()
		if framerate == 0 then continue end

		local mode = flipbook:Mode()
		local isPingPong = mode == Enum.ParticleFlipbookMode.PingPong

		local gridSize = flipbook:GridSize()
		local numFrames: number = flipbook:NumFrames() or gridSize.X * gridSize.Y
		local cycleDuration = (if isPingPong and numFrames > 1 then (numFrames - 1) * 2 else numFrames) / framerate

		local elapsed = if flipbook:Synchronized()
			then lifetime
			else flipbook:Elapsed(flipbook:Elapsed() :: number + deltaTime)

		local cycleStep = math.floor(elapsed % cycleDuration * framerate)

		local oldIndex, newIndex =
			flipbook:Index(),
			flipbook:Index(
				if isPingPong and cycleStep >= numFrames
					then (numFrames - 1) - (cycleStep - (numFrames - 1))
					else cycleStep
			)

		if oldIndex == newIndex then continue end

        -- stylua: ignore
		local position: Vector2 =
            if mode == Enum.ParticleFlipbookMode.Random then
                Vector2.new(math.random(0, gridSize.X - 1), math.random(0, gridSize.Y - 1))
			else
                Vector2.new(newIndex % gridSize.X , math.floor(newIndex / gridSize.X))

		if flipbook.instance.ClassName == "ImageLabel" then
			flipbook.instance.Position = UDim2.fromScale(-position.X, -position.Y)
		elseif flipbook.instance.ClassName == "Decal" then
			flipbook.instance.UVOffset = position * (Vector2.one / gridSize)
		end
	end
end

return Flipbook
