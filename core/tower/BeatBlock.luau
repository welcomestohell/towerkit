const Players = game:GetService "Players"

const marrays = require "@libs/collections/marrays"
const tables = require "@libs/collections/tables"
const emission = require "@libs/emission"
const destruction = require "@libs/memory/destruction"
const std = require "@libs/std"
const toggle = require "@libs/toggle"
const tweens = require "@libs/tweens"

const BeatBlock = std.Mechanic {
	emoji = "🎶",
	name = "BeatBlock",
	description = "Periodically toggles sequential descendants with beat synchronization.",
	instanceType = std.isA.Instance(),

	Enabled = std.Attribute("Enabled", std.gt.boolean(), true),
	Interval = std.Attribute("Interval", std.gt.positiveNumber, 1),
	Index = std.Attribute("Index", std.gt.positiveNumber, 0),

	std.AttributeSection "Emission",
	EmitSwitchedTag = std.Attribute("EmitSwitchedTag", std.gt.tag, "BeatBlock: On Switched"),
	ParentEmittersToClosest = std.Attribute("ParentEmittersToClosest", std.gt.boolean(), true),

	std.AttributeSection "Indicator",
	IndicatorEnabled = std.Attribute("IndicatorEnabled", std.gt.boolean(), true),
	IndicatorInterval = std.Attribute("IndicatorInterval", std.gt.positiveNumber, 0.5),
	IndicatorSizeMultiplier = std.Attribute("IndicatorSizeMultiplier", std.gt.NumberRange, NumberRange.new(0.5, 0.995)),
	IndicatorStyle = std.Attribute("IndicatorStyle", std.gt.enumOf(Enum.EasingStyle), Enum.EasingStyle.Linear),
	IndicatorDirection = std.Attribute(
		"IndicatorDirection",
		std.gt.enumOf(Enum.EasingDirection),
		Enum.EasingDirection.Out
	),
}

export type BeatBlockMechanic = std.Mechanic<typeof(BeatBlock), {
	highestIndex: number,
	blocks: { { BasePart } },
	emitters: { [Instance]: true },
}>

function BeatBlock.calculateHighestIndex(beatblock: BeatBlockMechanic)
	local highestIndex = 0
	for index, blocks in beatblock.blocks do
		if #blocks ~= 0 then highestIndex = math.max(highestIndex, index) end
	end
	beatblock.highestIndex = highestIndex
	return highestIndex
end

function BeatBlock.calculateNextIndex(beatblock: BeatBlockMechanic): number
	return beatblock:Index() :: number % beatblock.highestIndex + 1
end

function BeatBlock.processChild(beatblock: BeatBlockMechanic, child: Instance)
	if not child:IsA "BasePart" then return end
	const index = tonumber(child.Name)

	const childLife = beatblock.life:extend()
	childLife:destroyOn(child.Destroying)
	childLife:destroyOn(child:GetPropertyChangedSignal "Parent")
	childLife:add(child:GetPropertyChangedSignal("Name"):Once(function()
		childLife:destroy()
		beatblock:processChild(child)
	end))

	if index then
		marrays.push(beatblock.blocks, index, child)
		beatblock:calculateHighestIndex()
		childLife:addMany(function()
			marrays.remove(beatblock.blocks, index, child)
			beatblock:calculateHighestIndex()
		end)
	end
end

function BeatBlock.onStart(self: typeof(BeatBlock), beatblock: BeatBlockMechanic, level: std.Level)
	beatblock.highestIndex = 0
	beatblock.blocks = {}
	beatblock.emitters = tables.weak "k"

	beatblock.life:addMany(
		beatblock.instance.ChildAdded:Connect(function(child)
			beatblock.processChild(beatblock, child)
		end),
		beatblock.instance.DescendantAdded:Connect(function(descendant)
			if descendant:HasTag(beatblock:EmitSwitchedTag()) then beatblock.emitters[descendant] = true end
		end),
		beatblock.EmitSwitchedTag:onChange(beatblock, function()
			table.clear(beatblock.emitters)
			for _, descendant in beatblock.instance:GetDescendants() do
				if descendant:HasTag(beatblock:EmitSwitchedTag()) then beatblock.emitters[descendant] = true end
			end
		end)
	)

	for _, descendant in beatblock.instance:GetDescendants() do
		if descendant.Parent == beatblock.instance then beatblock:processChild(descendant) end
		if descendant:HasTag(beatblock:EmitSwitchedTag()) then beatblock.emitters[descendant] = true end
	end

	const indicators = {}
	while true do
		const indexNow = beatblock:Index(beatblock:calculateNextIndex()) :: number

		const parentEmittersToClosest = beatblock:ParentEmittersToClosest()
		local closestDistance, closestBlock = math.huge, nil
		for index, blocks in beatblock.blocks do
			const enabled = index == indexNow
			for _, block in blocks do
				toggle.toggleInstance(enabled, block)

				if enabled and parentEmittersToClosest then
					const distance = Players.LocalPlayer:DistanceFromCharacter(block.Position)
					if distance < closestDistance then
						closestDistance, closestBlock = distance, block
					end
				end
			end
		end

		if closestBlock then
			for emitter in beatblock.emitters do
				emitter.Parent = closestBlock
			end
		end

		emission.emitTaggedDescendants(beatblock.instance, beatblock:EmitSwitchedTag())

		const indicatorEnabled = beatblock:IndicatorEnabled()
		const indicatorTime = if indicatorEnabled then beatblock:IndicatorInterval() else 0
		task.wait(beatblock:Interval() - indicatorTime)
		if indicatorEnabled then
			destruction.destroy(indicators)

			const sizeMultiplier = beatblock:IndicatorSizeMultiplier()
			const startingSizeMultiplier = Vector3.one * sizeMultiplier.Min
			const endingSizeMultiplier = Vector3.one * sizeMultiplier.Max

			const tweenConfiguration: tweens.TweenConfiguration = {
				duration = indicatorTime,
				style = beatblock:IndicatorStyle(),
				direction = beatblock:IndicatorDirection(),
			}

			const nextBlocks = beatblock.blocks[beatblock:calculateNextIndex()] or {} :: never

			for index, block in nextBlocks do
				const indicator = Instance.fromExisting(block)
				indicator.Name ..= "Indicator"
				indicator.Material = Enum.Material.SmoothPlastic
				indicator.Transparency = 1
				indicator.Size *= startingSizeMultiplier
				indicators[index] = indicator
				indicator.Parent = block.Parent

				tweens.play(indicator, {
					Size = block.Size * endingSizeMultiplier,
					Transparency = math.map(toggle.TransparencyEnabled(block), 0, 1, 0.5, 1),
				}, tweenConfiguration)
			end

			task.wait(indicatorTime)
		end
	end
end

return BeatBlock
