local Mechanic = require("./Mechanic")
local functions = require("./functions")
local tables = require("@libs/collections/tables")

local ScriptCollector = {}
ScriptCollector.__index = ScriptCollector

export type ScriptCollector = setmetatable<{
	mechanicImplementations: { Mechanic.MechanicImplementation },
	mechanicImplementationByTag: { [string]: Mechanic.MechanicImplementation },
	mechanicTags: { string },
}, typeof(ScriptCollector)>

function ScriptCollector.new(): ScriptCollector
	return setmetatable({
		mechanicImplementations = {},
		mechanicImplementationByTag = {},
		mechanicTags = {},
	}, ScriptCollector)
end

function ScriptCollector.tryMechanicImplementation(
	self: ScriptCollector,
	implementation: Mechanic.MechanicImplementation
)
	if Mechanic.isMechanicImplementation(implementation) then
		local tagged = self.mechanicImplementationByTag[implementation.instanceTag]
		if tagged then
			error("Duplicate mechanic found")
		end
		self.mechanicImplementationByTag[implementation.instanceTag] = implementation
		table.insert(self.mechanicImplementations, implementation)
		table.insert(self.mechanicTags, implementation.instanceTag)
		table.sort(self.mechanicTags)
	end
end

function ScriptCollector.tryRegister(self: ScriptCollector, x: any)
	self:tryMechanicImplementation(x)
end

function ScriptCollector.tryInstance(self: ScriptCollector, instance: Instance)
	if not instance:IsA("ModuleScript") then
		return
	end

	local requireSuccess, required = pcall(require, instance)
	if not requireSuccess then
		return
	end

	self:tryRegister(required)
end

function ScriptCollector.tryInstances(self: ScriptCollector, instances: { Instance })
	for _, instance in instances do
		self:tryInstance(instance)
	end
end

function ScriptCollector.clone(self: ScriptCollector): ScriptCollector
	return setmetatable({
		mechanicImplementations = table.clone(self.mechanicImplementations),
		mechanicImplementationByTag = table.clone(self.mechanicImplementationByTag),
		mechanicTags = table.clone(self.mechanicTags),
	}, ScriptCollector)
end

return table.freeze(ScriptCollector)
