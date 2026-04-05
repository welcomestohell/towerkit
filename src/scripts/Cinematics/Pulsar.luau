local std = require("@libs/std")

local Pulsar = std.Mechanic({})
export type PulsarMechanic = std.Mechanic<typeof(Pulsar)>
Pulsar.instanceTag = "Pulsar"
Pulsar.instanceType = std.isA.Instance()
Pulsar.debuggerEmoji = "🌈"

-- TODO: implement

return Pulsar
