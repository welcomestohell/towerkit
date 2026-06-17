const logger = require "@core/shared/logger"
const std = require "@libs/std"
const toggle = require "@libs/toggle"
const touch = require "@libs/touch"
const tweens = require "@libs/tweens"

const SHRINK_DIRECTION_OFFSETS = {
	Center = Vector3.zero,
	Top = Vector3.yAxis,
	Bottom = -Vector3.yAxis,
	Front = Vector3.zAxis,
	Back = -Vector3.zAxis,
	Left = -Vector3.xAxis,
	Right = Vector3.xAxis,
}

const VANISH_HANDLERS: { [VanisherMode]: (vanisher: VanisherMechanic, child: VanisherChild, toucher: BasePart) -> () } =
	{}

function VANISH_HANDLERS.Fade(vanisher, child)
	tweens
		.playAlwaysFromAttributes(child.part, {
			Transparency = child.touchedTransparency,
		}, vanisher.Tween, vanisher.instanceConfiguration).Completed
		:Wait()

	vanisher:vanish(child)
end

const Vanisher = std.Mechanic {
	emoji = "🫥",
	name = "Vanisher",
	description = "When activated, it gradually disappears to become uncollidable.",
	instanceType = std.gt.instanceTree {
		VanisherSelectionBox = std.isA.SelectionBox(),
	},

	Active = std.Attribute("Active", std.gt.boolean(), false),
	Cooldown = std.Attribute("Cooldown", std.gt.positiveNumber, 0),
	Mode = std.Attribute("Mode", std.gt.literals("Fade", "Blink", "Constant", "Shrink", "Fall"), "Fade"),
	Inverted = std.Attribute("Inverted", std.gt.boolean(), false),

	std.AttributeSection "Blink",
	BlinkCount = std.Attribute("BlinkCount", std.gt.number { range = { min = 0, max = math.huge }, integer = true }, 3),

	std.AttributeSection "Constant",
	ConstantNoRecovery = std.Attribute("ConstantNoRecovery", std.gt.boolean(), false),

	std.AttributeSection "Shrink",
	ShrinkToZero = std.Attribute("ShrinkToZero", std.gt.boolean(), false),
	ShrinkDirection = std.Attribute(
		"ShrinkDirection",
		std.gt.literals("Center", "Top", "Bottom", "Front", "Back", "Left", "Right"),
		"Center"
	),

	std.AttributeSection "Tags",
	IgnoreTag = std.Attribute("IgnoreTag", std.gt.tag, "Vanisher: Ignore"),
	EmitActivatedTag = std.Attribute("EmitActivatedTag", std.gt.tag, "Vanisher: On Activated"),
	EmitBlinkedTag = std.Attribute("EmitActivatedTag", std.gt.tag, "Vanisher: On Blinked"),
	EmitVanishedTag = std.Attribute("EmitVanishedTag", std.gt.tag, "Vanisher: On Vanished"),
	EmitRespawnedTag = std.Attribute("EmitRespawnedTag", std.gt.tag, "Vanisher: On Respawned"),

	std.AttributeSection "Touch",
	Touch = touch.useAttributes(),

	std.AttributeSection "Tween",
	Tween = tweens.useAttributes(),
	Respawn = tweens.useAttributes "Respawn",
}

export type VanisherMechanic = std.Mechanic<
	typeof(Vanisher),
	{ vanishLife: std.Life, children: { [BasePart]: VanisherChild } }
>
export type VanisherMode = typeof(Vanisher.Mode:type())
export type VanisherChild = {
	part: BasePart,

	defaultTransparency: number,
	touchedTransparency: number,

	defaultCanCollide: boolean,
	touchedCanCollide: boolean,

	originalTransparency: number,

	selection: SelectionBox?,
}

function Vanisher.respawn(vanisher: VanisherMechanic, child: VanisherChild)
	child.part.CanCollide = child.defaultCanCollide
	child.part.CanTouch = true

	if child.selection then child.selection.Color3 = Color3.new() end

	tweens.playAlwaysFromAttributes(child.part, {
		Transparency = child.defaultTransparency,
	}, vanisher.Respawn, vanisher.instanceConfiguration)

	vanisher:Active(false)

	vanisher:Emit(vanisher:EmitRespawnedTag())
end

function Vanisher.vanish(vanisher: VanisherMechanic, child: VanisherChild)
	child.part.CanCollide = child.touchedCanCollide
	child.part.CanTouch = false
	child.part.Transparency = child.touchedTransparency

	if child.selection then child.selection.Color3 = Color3.new(1, 0, 0) end

	vanisher:Emit(vanisher:EmitVanishedTag())

	task.delay(vanisher:Cooldown(), function()
		if vanisher.life.destroyed then return end

		vanisher:respawn(child)
	end)
end

function Vanisher.spawn(vanisher: VanisherMechanic, child: VanisherChild, toucher: BasePart)
	if vanisher:Active() then return end

	if vanisher.vanishLife and not vanisher.vanishLife.destroyed then vanisher.vanishLife:destroy() end
	vanisher.vanishLife = vanisher.life:extend()

	const mode = vanisher:Mode()
	const handler = VANISH_HANDLERS[mode]
	if not handler then
		logger:Warn("Unsupported vanisher mode:", mode)
		return
	end

	if mode == "Constant" then return end

	vanisher:Active(true)
	handler(vanisher, child, toucher)
end

function Vanisher.processChild(vanisher: VanisherMechanic, child: Instance)
	if child:HasTag(vanisher:IgnoreTag()) or not child:IsA "BasePart" then return end

	local selection = child:FindFirstChild "VanisherSelectionBox"
	local defaultTransparency = if vanisher:Inverted() then 1 else child.Transparency
	local touchedTransparency = 1 - defaultTransparency
	local defaultCanCollide = not vanisher:Inverted()
	local touchedCanCollide = not defaultCanCollide

	local vanisherChild: VanisherChild = {
		part = child,
		selection = if selection and selection:IsA "SelectionBox" then selection else nil,

		originalTransparency = child.Transparency,

		defaultTransparency = defaultTransparency,
		touchedTransparency = touchedTransparency,

		defaultCanCollide = defaultCanCollide,
		touchedCanCollide = touchedCanCollide,
	}

	child.Transparency = defaultTransparency
	child.CanCollide = defaultCanCollide

	vanisher.children[child] = vanisherChild

	vanisher.life:addMany(
		child.Destroying:Connect(function()
			vanisher.children[child] = nil
		end),
		child.Touched:Connect(function(toucher: BasePart)
			if touch.isToucherValid(vanisher.Touch, child, vanisher.instanceConfiguration, toucher) then
				-- TODO: we should swap toucher to wholebody if its the
				-- character, but blocked on custom hitboxes
				vanisher:spawn(vanisherChild, toucher)
			end
		end)
	)
end

function Vanisher.onStart(self: typeof(Vanisher), vanisher: VanisherMechanic)
	vanisher.children = {}

	if vanisher.instance:IsA "BasePart" then
		vanisher:processChild(vanisher.instance)
	else
		vanisher.life:add(vanisher.instance.ChildAdded:Connect(function(child)
			vanisher:processChild(child)
		end))
		for _, child in vanisher.instance:GetChildren() do
			vanisher:processChild(child)
		end
	end
end

return Vanisher
