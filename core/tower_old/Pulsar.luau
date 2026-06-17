local std = require "@libs/std"

local Pulsar = std.Mechanic {}
export type PulsarMechanic = std.Mechanic<typeof(Pulsar)>
Pulsar.name = "Pulsar"
Pulsar.instanceType = std.isA.Instance()
Pulsar.emoji = "🌈"

-- TODO: implement

return Pulsar
