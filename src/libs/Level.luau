local RunService = game:GetService("RunService")

local Life = require("@libs/memory/Life")
local Log = require("./Log")
local Mechanic = require("./Mechanic")
local Promise = require("@pkgs/Promise")
local Result = require("./Result")
local ScriptCollector = require("./ScriptCollector")
local activation = require("./activation")
local functions = require("./functions")
local gt = require("@libs/gt")
local tables = require("@libs/collections/tables")
local threadpool = require("@libs/threadpool")
local types = require("@libs/activation/types")

local log = Log.new("Level")

--[=[
	@class Level
	@tag Class
	@tag Library
	
	Orchestrator of scripts and mechanics in levels.

	Levels can be traversed by the player with mechanics, level scripts, and
	some starting positions. Alongside towers, Levels are also used to represent
	Chapters in Welcome To Hell's Campaign.

	This class should not be constructed by tower scripts. Many Mechanic
	methods provide a handle to a tower's Level as the last argument.
]=]
local Level = {}
Level.__index = Level
Level.baseScripts = ScriptCollector.new()
Level.activeLevels = {} :: { Level }

Level.LevelInstance = gt.build(gt.instanceTree({
	Mechanics = gt.Instance(),
	Scripts = gt.optional(gt.Instance()),
	SpawnCharacter = gt.isA.BasePart(),
	SpawnCamera = gt.optional(gt.isA.BasePart()),
}))

export type LevelInstance = typeof(Level.LevelInstance:type())

export type Level = setmetatable<{
	life: Life.Life,
	name: string,
	instance: LevelInstance,

	scripts: ScriptCollector.ScriptCollector,
	mechanics: { Mechanic.Mechanic<any> },
	mechanicsByImplementations: { [Mechanic.MechanicImplementation]: { Mechanic.Mechanic<any> } },
	mechanicsByInstance: { [Instance]: { Mechanic.Mechanic<any> } },

	startTimestamp: number,
}, typeof(Level)>

function Level.new(
	outerLife: Life.Life,
	name: string,
	instance: Instance
): Result.Result<Level, { id: "invalidInstance", cause: gt.Cause }>
	local isInstanceValid, instanceCause = Level.LevelInstance:matches(instance)

	if isInstanceValid then
		local self: Level = setmetatable({
			life = outerLife:extend(),
			name = name,
			instance = instance :: LevelInstance,

			scripts = Level.baseScripts:clone(),
			mechanics = {},
			mechanicsByImplementations = {},
			mechanicsByInstance = tables.weak("k"),

			startTimestamp = os.clock(),
		}, Level)

		return Result.Ok(self)
	end

	return Result.Err({ id = functions.literal("invalidInstance"), cause = instanceCause })
end

function Level.getLifetime(self: Level)
	return os.clock() - self.startTimestamp
end

function Level.loadMechanicsFromInstance(self: Level, instance: Instance)
	for _, tag in instance:GetTags() do
		local implementation = self.scripts.mechanicImplementationByTag[tag]
		if implementation then
			local mechanicResult = Mechanic.tryMechanize(implementation, self.life, instance)
			if mechanicResult:isOk() then
				local mechanic = mechanicResult:unwrap()

				table.insert(self.mechanics :: any, mechanic)

				local mechanicsByImplementations = self.mechanicsByImplementations[implementation]
				if not mechanicsByImplementations then
					mechanicsByImplementations = {}
					self.mechanicsByImplementations[implementation] = mechanicsByImplementations
				end
				table.insert(mechanicsByImplementations :: any, mechanic)

				local mechanicsByInstance = self.mechanicsByInstance[instance]
				if not mechanicsByInstance then
					mechanicsByInstance = {}
					self.mechanicsByInstance[instance] = mechanicsByInstance
				end
				table.insert(mechanicsByInstance :: any, mechanic)
			end
		end
	end
end

function Level.startMechanic(self: Level, mechanic: Mechanic.Mechanic<any>)
	local implementation: Mechanic.MechanicImplementation = mechanic.implementation

	if implementation.onActivated then
		log:warn(`\
			{implementation.instanceTag} implemented \`onActivated\` which has no behavior, did you mean \
			to implement \`onActivate\`?\
		`)
	end

	if implementation.onActivate then
		local activationAttributes = implementation.Activation :: types.ActivationAttributes
		if not activationAttributes then
			Mechanic.attributeSection(implementation :: any, "Activation")
			activationAttributes = activation.useAttributes(implementation :: any)
			implementation.activation = activationAttributes
		end

		activation.bindActivation({
			attributes = activationAttributes,
			activationLife = mechanic.life,
			instanceLife = mechanic.life,
			instance = mechanic.instance,
			instanceConfiguration = mechanic.instanceConfiguration,
			onActivate = function(context: activation.ActivationContext)
				implementation:onActivate(mechanic, self)
			end,
		})
	end

	if implementation.onStart then
		self.life:add(threadpool.spawn(implementation.onStart, implementation, mechanic, self))
	end
end

function Level.spawnMechanicImplementationMethod(self: Level, method: keyof<Mechanic.MechanicImplementation>, ...: any)
	for _, implementation in self.scripts.mechanicImplementations do
		if implementation[method] then
			self.life:add(threadpool.spawn((implementation :: any)[method], implementation, ...))
		end
	end
end

function Level.getMechanics<Self>(self: Level, implementation: Self): { Mechanic.Mechanic<Self> }
	return self.mechanicsByImplementations[implementation] :: any or {}
end

function Level.start(self: Level)
	self.startTimestamp = os.clock()

	self.life:add(self.instance)
	self.life:destroyOn(self.instance.Destroying)

	local levelInstance = self.instance :: Instance
	local levelScripts = levelInstance:FindFirstChild("Scripts")
	if levelScripts then
		self.scripts:tryInstances(levelScripts:GetDescendants())
	end

	for _, instance in self.instance:WaitForChild("Mechanics"):GetDescendants() do
		self:loadMechanicsFromInstance(instance)
	end

	local initThreads: { Promise.Promise } = {}
	for _, implementation in self.scripts.mechanicImplementations do
		if implementation.onInit then
			table.insert(
				initThreads,
				Promise.try(implementation.onInit, implementation, self):catch(function(e)
					log:warn(`Failed to initialize mechanic implementation "{implementation.instanceTag}":`, e)
				end)
			)
		end
	end

	Promise.all(initThreads):await()

	for _, mechanic in self.mechanics do
		threadpool.spawn(Level.startMechanic, self, mechanic)
	end

	self.life:add(RunService.PreSimulation:Connect(function(deltaTime)
		self:spawnMechanicImplementationMethod("onPreSimulation", deltaTime, self)
	end))

	self.life:add(RunService.PostSimulation:Connect(function(deltaTime)
		self:spawnMechanicImplementationMethod("onPostSimulation", deltaTime, self)
	end))

	self.life:add(RunService.PreRender:Connect(function(deltaTime)
		self:spawnMechanicImplementationMethod("onPreRender", deltaTime, self)
	end))

	self.life:add(RunService.PreAnimation:Connect(function(deltaTime)
		self:spawnMechanicImplementationMethod("onPreAnimation", deltaTime, self)
	end))

	table.insert(Level.activeLevels :: any, self)
	self.life:add(function()
		tables.findAndRemove(Level.activeLevels :: any, self)
	end)
end

function Level.__tostring(self: Level)
	return `Level({self.name})`
end

return table.freeze(Level)
