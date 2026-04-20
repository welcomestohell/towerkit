local gt = require("@libs/gt")
local tables = require("@libs/collections/tables")
local Life = require("@libs/memory/Life")
local Result = require("@libs/Result")
local ScriptCollector = require("@libs/core/ScriptCollector")
local MechanicImplementation = require("@libs/core/MechanicImplementation")

local Level = {
	baseScripts = ScriptCollector.new(),
	activeLevels = {} :: { Level },

	LevelInstance = gt.build(gt.instanceTree({
		Mechanics = gt.Instance(),
		Scripts = gt.optional(gt.Instance()),
		SpawnCharacter = gt.isA.BasePart(),
		SpawnCamera = gt.optional(gt.isA.BasePart()),
	})),
}
Level.__index = Level

export type Level = setmetatable<{
	life: Life.Life,
	name: string,
	instance: LevelInstance,

	scripts: ScriptCollector.ScriptCollector,
	mechanics: { MechanicImplementation.Mechanic<any> },
	mechanicsByImplementations: {
		[MechanicImplementation.MechanicImplementation]: { MechanicImplementation.Mechanic<any> },
	},
	mechanicsByInstance: { [Instance]: { MechanicImplementation.Mechanic<any> } },

	startTimestamp: number,
}, typeof(Level)>

export type LevelInstance = typeof(Level.LevelInstance:type())

function Level.new(outerLife: Life.Life, name: string, instance: Instance): Result.Result<Level, string>
	local isInstanceValid, instanceCause = Level.LevelInstance:matches(instance)

	if not isInstanceValid then
		return Result.Err(`Invalid level instance: {instanceCause:formatErr()}`)
	end

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

function Level.getLifetime(self: Level)
	return os.clock() - self.startTimestamp
end

return table.freeze(Level)
