local Mechanic = require "@libs/core/Mechanic"
local Promise = require "@roblox_packages/Promise"
local logger = require "@core/shared/logger"

--[=[
    @class ScriptCollector
    @since 0.1.0
    @tag Class
    @tag Library

    Collects mechanic implementations from module scripts for use in levels.
]=]
local ScriptCollector = {}
ScriptCollector.__index = ScriptCollector

export type ScriptCollector = setmetatable<{
	--[=[
        @prop mechanicImplementations { MechanicImplementation }
        @within ScriptCollector

        All mechanic implementations that has been collected.
    ]=]
	mechanicImplementations: { Mechanic.AnyMechanicImplementation },

	--[=[
        @prop mechanicImplementationByName { [string]: MechanicImplementation }
        @within ScriptCollector

        All mechanic implementations that has been collected mapped by it's
        name.

        This is distinct from the matching CollectionService tag, which follows
        `Mechanic: {name}`.
    ]=]
	mechanicImplementationByName: { [string]: Mechanic.AnyMechanicImplementation },

	--[=[
        @prop mechanicTags { string }
        @within ScriptCollector

        All mechanic tags used in mechanic implementations.
    ]=]
	mechanicTags: { string },
}, typeof(ScriptCollector)>

--[=[
    @within ScriptCollector
    @since 0.1.0

    Constructs an empty ScriptCollector.
]=]
function ScriptCollector.new(): ScriptCollector
	return setmetatable({
		mechanicImplementations = {},
		mechanicImplementationByName = {},
		mechanicTags = {},
	}, ScriptCollector)
end

--[=[
    @within ScriptCollector
    @since 0.1.0

    Constructs a new ScriptCollector keeping it's collected scripts. Levels,
    for example, clones a base ScriptCollector with core scripts.

    @param self ScriptCollector -- The ScriptCollector to use.
    @return ScriptCollector -- A new ScriptCollector inherited from the base ScriptCollector.
]=]
function ScriptCollector.clone(self: ScriptCollector): ScriptCollector
	return setmetatable({
		mechanicImplementations = table.clone(self.mechanicImplementations),
		mechanicImplementationByName = table.clone(self.mechanicImplementationByName),
		mechanicTags = table.clone(self.mechanicTags),
	}, ScriptCollector)
end

--[=[
    @within ScriptCollector
    @since 0.1.0

    Processes a ModuleScript instance, collecting MechanicImplementations if it
    is returned from the module.

    @param self ScriptCollector -- The ScriptCollector to use.
    @param instance ModuleScript -- The ModuleScript to collect.
]=]
function ScriptCollector.collectModuleScript(self: ScriptCollector, instance: ModuleScript)
	local requireSucess, requiredOrError = pcall(require, instance)
	if not requireSucess then
		logger:Error("Module", instance:GetFullName(), "failed to be required:", requiredOrError)
	end

	if Mechanic.isMechanicImplementation(requiredOrError) then
		local implementation = Mechanic.downcast(requiredOrError)
		implementation.name = implementation.name or instance.Name

		if self.mechanicImplementationByName[implementation.name] then
			logger:Error(
				"Cannot collect mechanic implementation",
				instance:GetFullName(),
				"as it's instance tag",
				implementation.name,
				"is already registered; are you trying to `:override()` a mechanic?"
			)
			return
		end

		table.insert(self.mechanicImplementations, implementation)
		self.mechanicImplementationByName[implementation.name] = implementation
		table.insert(self.mechanicTags, implementation.name)
		table.sort(self.mechanicTags)
	end
end

--[=[
    @within ScriptCollector
    @since 0.1.0

    Processes a given Instance. If it is a ModuleScript, it is deferred to
    `ScriptCollector.collectModuleScript`.

    @param self ScriptCollector -- The ScriptCollector to use.
    @param instance Instance -- The Instance to collect.
]=]
function ScriptCollector.collectInstance(self: ScriptCollector, instance: Instance)
	if instance:IsA "ModuleScript" then self:collectModuleScript(instance) end
end

--[=[
    @within ScriptCollector
    @since 0.1.0

    Processes a given Instance. If it is a ModuleScript, it is deferred to
    `ScriptCollector.collectModuleScript`.

    Returns a Promise, which can be used with `Promise.all` to collect many
    instances parallel.

    @param self ScriptCollector -- The ScriptCollector to use.
    @param instance Instance -- The Instance to collect.
    @return Promise -- A Promise which resolves when the instance has been processed.
]=]
ScriptCollector.collectInstanceAsync =
	Promise.promisify(ScriptCollector.collectInstance) :: (self: ScriptCollector, instance: Instance) -> Promise.Promise

--[=[
    @within ScriptCollector
    @since 0.1.0

    Collects many instances in parallel.

    @param self ScriptCollector -- The ScriptCollector to use.
    @param instances { Instance } -- Instances to collect.
    @return Promise -- A Promise which resolves when all instances has been processed.
]=]
function ScriptCollector.collectInstancesAsync(self: ScriptCollector, instances: { Instance }): Promise.Promise
	local promises: { Promise.Promise } = {}
	for index, instance in instances do
		promises[index] = self:collectInstanceAsync(instance)
	end
	return Promise.all(promises)
end

return table.freeze(ScriptCollector)
