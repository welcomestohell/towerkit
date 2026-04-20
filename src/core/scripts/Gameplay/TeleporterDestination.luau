local ids = require("@libs/ids")
local std = require("@libs/std")

local TeleporterDestination = std.Mechanic({})
export type TeleporterDestinationMechanic = std.Mechanic<typeof(TeleporterDestination)>

TeleporterDestination.basename = "TeleporterDestination"
TeleporterDestination.instanceType = std.isA.BasePart()
TeleporterDestination.debuggerEmoji = "📍"

TeleporterDestination.Id = ids.withAttribute(TeleporterDestination)
TeleporterDestination.destinationsById = std.LevelState({} :: ids.MechanicsById<TeleporterDestinationMechanic>)

TeleporterDestination.Offset = std.Attribute("Offset", std.gt.CFrame(), CFrame.new(0, 2.5, 0))

function TeleporterDestination:onStart(destination: TeleporterDestinationMechanic, level: std.Level)
	ids.trackMechanic(level, destination, destination.destinationsById)
end

return TeleporterDestination
