local LevelState = require("./LevelState")
local Mechanic = require("./Mechanic")
local gt = require("./gt")
local std = require("./std")
local tables = require("./collections/tables")

export type MechanicsById<Mechanic> = { [string]: { Mechanic } }

local function withAttribute(implementation: Mechanic.MechanicImplementationLike)
	return implementation:attribute("Id", gt.optional(gt.string()), nil)
end

-- LUAU: needs generic bounds
local function trackMechanic<T>(level: std.Level, mechanic: T, mechanicsByIdState: LevelState.LevelState<MechanicsById<T>>)
	local oldId: string? = nil
	local mechanicsById = mechanicsByIdState:get(level);

	(mechanic :: any).Id:onBind(mechanic, function(newId: string?)
		if oldId then
			local oldIdMechanics = mechanicsById[oldId]
			tables.findAndRemove(oldIdMechanics, mechanic)
		end

		if newId then
			local newIdMechanics = mechanicsById[newId]
			if not newIdMechanics then
				newIdMechanics = {}
				mechanicsById[newId] = newIdMechanics
			end
			table.insert(newIdMechanics, mechanic)
		end

		oldId = newId
	end)
end

return table.freeze {
	withAttribute = withAttribute,
	trackMechanic = trackMechanic,
}
