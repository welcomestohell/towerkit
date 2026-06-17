const activation = require "@libs/activation"
const Level = require "@libs/core/Level"
const std = require "@libs/std"
const press = require "@libs/press"
const Promise = require "@roblox_packages/Promise"

const BoxSpawner = std.Mechanic {
	emoji = "📦",
	name = "BoxSpawner",
	description = "When activated, spawns it's Box instance.",
	instanceType = std.gt.instanceTree {
		Button = std.isA.BasePart(),
		Box = std.isA.PVInstance(),
		Spawn = std.isA.BasePart(),
	},

	Cooldown = std.Attribute("Cooldown", std.gt.positiveNumber, 0),
	Debounced = std.Attribute("Debounced", std.gt.boolean(), false),
	SpawnOnStart = std.Attribute("SpawnOnStart", std.gt.boolean(), false),
	AnchoredTag = std.Attribute("AnchoredTag", std.gt.tag, "Box: Anchored"),

	std.AttributeSection "Activation",
	Activation = activation.useAttributes(),

	std.AttributeSection "Press",
	Press = press.useAttributes(),
}

export type BoxSpawnerMechanic = std.Mechanic<typeof(BoxSpawner), { template: PVInstance, boxLife: std.Life? }>

function BoxSpawner.spawn(spawner: BoxSpawnerMechanic, level: std.Level)
	if spawner.boxLife then spawner.boxLife:destroy() end

	local boxLife = spawner.life:extend()
	spawner.boxLife = boxLife

	local box = boxLife:add(spawner.template:Clone())
	box.Parent = spawner.instance
	box:PivotTo(spawner.instance.Spawn.CFrame)

	local anchoredTag = spawner:AnchoredTag()

	local descendants = box:GetDescendants()
	table.insert(descendants, box)
	for _, descendant in descendants do
		descendant:AddTag "Box"
		if descendant:IsA "BasePart" and not descendant:HasTag(anchoredTag) then descendant.Anchored = false end
	end

	local instancePromises, loadPromises = level:loadDescendantInstancesAsync(box)
	Promise.all(instancePromises):await()
	Promise.all(loadPromises):await()
end

function BoxSpawner:getActivationInstances(spawner: BoxSpawnerMechanic)
	return spawner.instance.Button
end

function BoxSpawner.onActivate(self: typeof(BoxSpawner), spawner: BoxSpawnerMechanic, level: std.Level)
	if spawner:Debounced() then return end

	spawner:Debounced(true)
	spawner.Activation.Enabled(spawner, false)

	spawner.life:delay(spawner:Cooldown(), function(spawner: BoxSpawnerMechanic)
		spawner:Debounced(false)
		spawner.Activation.Enabled(spawner, true)
	end, spawner)

	spawner.life:add(press.usePress {
		instance = spawner.instance.Button,
		instanceConfiguration = spawner.instanceConfiguration,
		attributes = self.Press,
		flash = true,
	})

	spawner:spawn(level)
end

function BoxSpawner:onStart(spawner: BoxSpawnerMechanic, level: std.Level)
	-- BoxSpawner is already loaded by the time this is called. We add the tag
	-- here so spawned boxes don't automatically load until we're done
	-- intializing them.
	spawner.instance:AddTag(Level.DO_NOT_LOAD_TAG)

	spawner.template = spawner.instance.Box
	spawner.template.Parent = nil

	spawner.life:add(spawner.template)

	if spawner:SpawnOnStart() then spawner:spawn(level) end
end

return BoxSpawner
