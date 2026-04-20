local std = require("@libs/std")

local Breakable = std.Mechanic({})
export type BreakableMechanic = std.Mechanic<typeof(Breakable)>
Breakable.basename = "Breakable"
Breakable.instanceType = std.isA.Instance()
Breakable.debuggerEmoji = "💥"

return Breakable
