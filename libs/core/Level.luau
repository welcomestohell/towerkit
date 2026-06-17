local RunService = game:GetService "RunService"

local Life = require "@libs/memory/Life"
local Mechanic = require "@libs/core/Mechanic"
local Promise = require "@roblox_packages/Promise"
local Result = require "@libs/Result"
local ScriptCollector = require "@libs/core/ScriptCollector"
local activation = require "@libs/activation"
local gt = require "@libs/vendor/gt"
local marrays = require "@libs/collections/marrays"
local mechanize = require "@libs/core/mechanize"
local mmaps = require "@libs/collections/mmaps"
local prvd = require "@roblox_packages/prvd"
local tables = require "@libs/collections/tables"
local threadpool = require "@libs/threadpool"
const toggle = require "@libs/toggle"

type AnyImplementation = Mechanic.AnyMechanicImplementation
type MechanicImplementation = Mechanic.MechanicImplementation
type Mechanic<Implementation = any, Mixin = {}> = Mechanic.Mechanic<Implementation, Mixin>

local Level = {}
Level.__index = Level
Level.DO_NOT_LOAD_TAG = "Level: Do Not Load"
Level.baseScripts = ScriptCollector.new()
Level.activeLevels = {} :: { Level }
Level.LevelInstance = gt.build(gt.instanceTree {
	Mechanics = gt.Instance(),
	Spawn = gt.isA.BasePart(),
})

export type LevelInstance = typeof(Level.LevelInstance:type())

export type Level = setmetatable<{
	life: Life.Life,
	name: string,
	instance: LevelInstance,

	started: boolean,
	startedTimestamp: number,

	scripts: ScriptCollector.ScriptCollector,

	instanceByGroups: { [string]: { Instance } },

	mechanics: { Mechanic<any> },
	mechanicsByImplementations: { [AnyImplementation]: { Mechanic } },
	mechanicsByInstance: { [Instance]: { Mechanic } },

	implementationLifecycleListeners: { [prvd.Lifecycle<...any>]: { [AnyImplementation]: (...unknown) -> () } },
	implementationLifecycles: { [string]: prvd.Lifecycle<...any> },
	mechanicLifecycleListeners: { [prvd.Lifecycle<...any>]: { [Mechanic]: (...unknown) -> () } },
	mechanicLifecycles: { [string]: prvd.Lifecycle<...any> },
}, typeof(Level)>

function Level.new(outerLife: Life.Life, name: string, instance: Instance)
	local isInstanceValid, instanceCause = Level.LevelInstance:matches(instance)

	if not isInstanceValid then return Result.Err(`Invalid instance: {instanceCause:formatErr()}`) end

	local self: Level = setmetatable({
		life = outerLife:extend(),
		name = name,
		instance = instance :: LevelInstance,

		started = false,
		startedTimestamp = os.clock(),

		scripts = Level.baseScripts:clone(),

		instanceByGroups = {},

		mechanics = {},
		mechanicsByImplementations = {},
		mechanicsByInstance = tables.weak "k",

		-- HEAR ME OUT

		implementationLifecycleListeners = {},
		implementationLifecycles = {
			onInit = prvd.lifecycle("onInit", function(lifecycle: prvd.Lifecycle<Level>, level: any)
				local promises: { Promise.Promise } = {}
				for index, listener in lifecycle.callbacks do
					promises[index] = Promise.try(listener, level):catch(function(e)
						warn(`Failed to initialize mechanic implementation: {e}`)
					end)
				end
				Promise.all(promises):await()
			end),

			onPreRender = prvd.lifecycle<<(number, Level)>>("onPreRender", prvd.fireConcurrent),
			onPreAnimation = prvd.lifecycle<<(number, Level)>>("onPreAnimation", prvd.fireConcurrent),
			onPreSimulation = prvd.lifecycle<<(number, Level)>>("onPreSimulation", prvd.fireConcurrent),
			onPostSimulation = prvd.lifecycle<<(number, Level)>>("onPostSimulation", prvd.fireConcurrent),
		},

		mechanicLifecycleListeners = {},
		mechanicLifecycles = {
			onStart = prvd.lifecycle<<(Mechanic, Level)>>("onStart", prvd.fireConcurrent),
			onActivate = prvd.lifecycle<<(Mechanic, Level, {})>>("onActivate", prvd.fireConcurrent),
			bindActivation = prvd.lifecycle<<(Mechanic, Level)>>("bindActivation", prvd.fireConcurrent),
			getActivationInstances = prvd.lifecycle<<(Mechanic, Level)>>("getActivationInstances", prvd.fireConcurrent),
		},
	}, Level)

	self.life:add(function()
		for _, implementations in self.implementationLifecycleListeners do
			table.clear(implementations)
		end

		for _, mechanics in self.mechanicLifecycleListeners do
			table.clear(mechanics)
		end

		table.clear(self.implementationLifecycles)
		table.clear(self.implementationLifecycleListeners)
		table.clear(self.implementationLifecycles)
		table.clear(self.mechanicLifecycleListeners)
	end)

	return Result.Ok(self)
end

function Level.getLifetime(self: Level)
	assert(self.started, "Level hasn't started yet")
	return os.clock() - self.startedTimestamp
end

-- TODO: onMechanicAdded, onMechanicRemoved
function Level.getMechanics<Self>(self: Level, implementation: Self): { Mechanic<Self> }
	return self.mechanicsByImplementations[implementation] :: any or {}
end

-- TODO: onGroupedInstanceAdded, onGroupedInstanceRemoved
function Level.getGroupedInstances<Args...>(self: Level, group: string): { Instance }
	return marrays.get(self.instanceByGroups, group)
end

function Level.getListenerForMechanic<Args...>(
	self: Level,
	lifecycle: prvd.Lifecycle<Args...>,
	mechanic: Mechanic
): ((Args...) -> ())?
	return mmaps.get<<prvd.Lifecycle<...any>>>(self.mechanicLifecycleListeners, lifecycle)[mechanic]
end

function Level.getListenerForImplementation<Args...>(
	self: Level,
	lifecycle: prvd.Lifecycle<Args...>,
	implementation: AnyImplementation
): ((Args...) -> ())?
	return mmaps.get<<prvd.Lifecycle<...any>>>(self.implementationLifecycleListeners, lifecycle)[implementation]
end

function Level.registerLifecyclesForImplementation(self: Level, implementation: AnyImplementation)
	for _, lifecycle in self.implementationLifecycles do
		local method: (AnyImplementation, ...any) -> () = (implementation :: any)[lifecycle.method]
		if type(method) == "function" then
			local function listener(...)
				return method(implementation, ...)
			end
			mmaps.set(self.implementationLifecycleListeners, lifecycle, implementation, listener)
			lifecycle:register(listener)
		end
	end
end

function Level.registerLifecyclesForMechanic(self: Level, mechanic: Mechanic)
	for _, lifecycle in self.mechanicLifecycles do
		local implementation = mechanic.implementation
		local method: (AnyImplementation, Mechanic, ...any) -> () = (implementation :: any)[lifecycle.method]
		if type(method) == "function" then
			local function listener(...)
				return method(implementation, mechanic, ...)
			end
			mmaps.set(self.mechanicLifecycleListeners, lifecycle, mechanic, listener)
			lifecycle:register(listener)
		end
	end
end

function Level.bindActivation(self: Level, mechanic: Mechanic)
	local bindActivation = self:getListenerForMechanic<<(Level)>>(self.mechanicLifecycles.bindActivation, mechanic)
	if bindActivation then
		bindActivation(self)
		return
	end

	-- stylua: ignore
	local onActivate = self:getListenerForMechanic<<(Level, activation.ActivationEvent)>>(self.mechanicLifecycles.onActivate, mechanic)
	if not onActivate then return end

	local implementation: any = mechanic.implementation
	local activationAttributes = implementation.Activation :: activation.ActivationAttributes
	if not activationAttributes then
		activationAttributes = activation.useAttributes()
		implementation.Activation = activationAttributes
	end

	-- stylua: ignore
	local getActivationInstances = self:getListenerForMechanic<<(Level)>>(self.mechanicLifecycles.getActivationInstances, mechanic)
	local instance = getActivationInstances and getActivationInstances(self) or mechanic.instance
	const instances: { Instance } = type(instance) == "table" and instance or { instance }

	for _, instance in instances do
		activation.bindActivation {
			attributes = activationAttributes,
			activationLife = mechanic.life,
			instanceLife = mechanic.life,
			instance = instance,
			instanceConfiguration = mechanic.instanceConfiguration,
			onActivate = function(context: activation.ActivationContext, event: activation.ActivationEvent)
				onActivate(self, event)
			end,
		}
	end
end

function Level.loadInstance(self: Level, instance: Instance): { Mechanic }
	local mechanics = {}
	local shouldToggle = false

	for _, tag in instance:GetTags() do
		local name = string.match(tag, "Mechanic:%s?([%w_%-]+)")
		if name then
			local implementation = Mechanic.downcast(self.scripts.mechanicImplementationByName[name])
			if not implementation then continue end

			local mechanizeResult = mechanize(implementation, self.life, instance)
			if mechanizeResult:isErr() then continue end

			local mechanic: Mechanic = mechanizeResult:unwrap() :: any
			table.insert(self.mechanics, mechanic)
			table.insert(mechanics, mechanic)
			marrays.push(self.mechanicsByImplementations, implementation, mechanic)
			marrays.push(self.mechanicsByInstance, mechanic.instance :: Instance, mechanic)
			marrays.push(self.mechanicsByInstance, mechanic.instanceConfiguration, mechanic)
			self:registerLifecyclesForMechanic(mechanic)
		end

		local groupName = string.match(tag, "Group:%s?([%w_%-]+)")
		if groupName then
			shouldToggle = true
			marrays.push(self.instanceByGroups, groupName, instance)
			self.life:add(instance.Destroying:Once(function()
				marrays.remove(self.instanceByGroups, groupName, instance)
			end))
		end
	end

	if shouldToggle then toggle.toggleInstance(false, instance) end

	return mechanics
end

Level.loadInstanceAsync = Promise.promisify(Level.loadInstance)

function Level.loadDescendantInstancesAsync(self: Level, root: Instance, skipRoot: boolean?)
	local instancePromises: { Promise.Promise } = {}
	local loadPromises: { Promise.Promise } = if skipRoot then {} else { self:loadInstanceAsync(root) }

	for _, descendant in root:GetChildren() do
		if descendant:HasTag(Level.DO_NOT_LOAD_TAG) then continue end
		table.insert(loadPromises, self:loadInstanceAsync(descendant) :: Promise.Promise)
		local descendantPromises = self:loadDescendantInstancesAsync(descendant, true)
		table.move(descendantPromises, 1, #descendantPromises, #instancePromises + 1, instancePromises)
	end
	return instancePromises, loadPromises
end

function Level.start(self: Level)
	local self = self
	assert(not self.started, `Level {self.name} has already started`)
	self.started = true
	self.startedTimestamp = os.clock()

	local instancePromises, loadPromises = self:loadDescendantInstancesAsync(self.instance.Mechanics)
	Promise.all(instancePromises):await()
	Promise.all(loadPromises):await()

	for _, implementation in self.scripts.mechanicImplementations do
		self:registerLifecyclesForImplementation(implementation)
	end

	self.implementationLifecycles.onInit:fire(self)

	self.life:add(self.instance)
	self.life:destroyOn(self.instance.Destroying)

	-- const toggled = {}
	-- for group, instances in self.instanceByGroups do
	-- 	for _, instance in instances do
	-- 		if not toggled[instance] then
	-- 			toggled[instance] = true
	-- 			toggle.toggleInstance(false, instance)
	-- 		end
	-- 	end
	-- end
	-- table.clear(toggled)

	for _, mechanic in self.mechanics do
		self.life:add(threadpool.spawn(Level.bindActivation, self, mechanic))
	end

	self.mechanicLifecycles.onStart:fire(self)

	self.life:addMany(
		RunService.PreSimulation:Connect(function(dt)
			self.implementationLifecycles.onPreSimulation:fire(dt, self)
		end),
		RunService.PostSimulation:Connect(function(dt)
			self.implementationLifecycles.onPostSimulation:fire(dt, self)
		end),
		RunService.PreRender:Connect(function(dt)
			self.implementationLifecycles.onPreRender:fire(dt, self)
		end),
		RunService.PreAnimation:Connect(function(dt)
			self.implementationLifecycles.onPreAnimation:fire(dt, self)
		end),
		-- TODO: Should we keep this, now that we have 'Level: Do Not Load' tag?
		self.instance.DescendantAdded:Connect(function(instance)
			for _, mechanic in self:loadInstance(instance) do
				self.life:add(threadpool.spawn(Level.bindActivation, self, mechanic))
				local onStart = self:getListenerForMechanic<<Level>>(self.mechanicLifecycles.onStart, mechanic)
				if onStart then threadpool.spawn(onStart, self) end
			end
		end)
	)

	-- LUAU FIXME: this should typecheck fine?
	table.insert(Level.activeLevels :: { any }, self)
	self.life:add(function()
		tables.findAndRemove<<Level>>(Level.activeLevels, self)
	end)
end

function Level.__tostring(self: Level)
	return `Level({self.name})`
end

return table.freeze(Level)
