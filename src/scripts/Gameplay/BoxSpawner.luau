local std = require("@libs/std")

local BoxSpawner = std.Mechanic({})
export type BoxSpawnerMechanic = std.Mechanic<typeof(BoxSpawner), { template: PVInstance, boxLife: std.Life? }>
BoxSpawner.instanceTag = "BoxSpawner"
BoxSpawner.instanceType = std.gt.instanceTree({
	Button = std.isA.BasePart(),
	Box = std.isA.PVInstance(),
	Spawn = std.isA.BasePart(),
})
BoxSpawner.debuggerEmoji = "📦"

BoxSpawner.Cooldown = BoxSpawner:attribute("Cooldown", std.gt.positiveNumber, 0)
BoxSpawner.Debounced = BoxSpawner:attribute("Debounced", std.gt.boolean(), false)
BoxSpawner.SpawnOnStart = BoxSpawner:attribute("SpawnOnStart", std.gt.boolean(), false)

BoxSpawner.TagKeepAnchor = BoxSpawner:attribute("TagKeepAnchor", std.gt.string(), "KeepAnchor")

BoxSpawner:attributeSection("Activation")
BoxSpawner.Activation = std.useActivation(BoxSpawner)

function BoxSpawner.spawn(spawner: BoxSpawnerMechanic)
	if spawner.boxLife then
		spawner.boxLife:destroy()
		spawner.boxLife = nil
	end

	local boxLife = spawner.life:extend()
	spawner.boxLife = boxLife

	local box = boxLife:add(spawner.template:Clone())
	box.Parent = spawner.instance
	box:PivotTo(spawner.instance.SpawnPosition.CFrame)

	local tagKeepAnchor = spawner:TagKeepAnchor()

	local descendants = box:GetDescendants()
	table.insert(descendants, box)
	for _, descendant in descendants do
		if descendant:IsA("BasePart") and not descendant:HasTag(tagKeepAnchor) then
			descendant.Anchored = false
		end
	end
end

function BoxSpawner.onActivate(self: typeof(BoxSpawner), spawner: BoxSpawnerMechanic)
	if self:Debounced() then
		return
	end

	spawner:Debounced(true)
	spawner.Activation.Enabled(spawner, false)

	spawner:spawn()

	task.delay(spawner:Cooldown(), function(spawner: BoxSpawnerMechanic)
		spawner:Debounced(false)
		spawner.Activation.Enabled(spawner, true)
	end, spawner)
end

function BoxSpawner.onStart(self: typeof(BoxSpawner), spawner: BoxSpawnerMechanic)
	spawner.template = spawner.instance.Box
	spawner.template.Parent = nil

	spawner.life:add(spawner.template)

	if spawner:SpawnOnStart() then
		spawner:spawn()
	end
end

return BoxSpawner
