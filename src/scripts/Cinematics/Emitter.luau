local std = require("@libs/std")

local Emitter = std.Mechanic({})
export type EmitterMechanic = std.Mechanic<typeof(Emitter)>
Emitter.instanceTag = "Emitter"
Emitter.instanceType = std.isA.Instance()
Emitter.debuggerEmoji = "✨"

return Emitter
