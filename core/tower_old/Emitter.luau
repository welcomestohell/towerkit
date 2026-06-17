local std = require "@libs/std"

local Emitter = std.Mechanic {}
export type EmitterMechanic = std.Mechanic<typeof(Emitter)>
Emitter.name = "Emitter"
Emitter.instanceType = std.isA.Instance()
Emitter.emoji = "✨"

return Emitter
