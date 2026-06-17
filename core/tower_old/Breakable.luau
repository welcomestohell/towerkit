local std = require "@libs/std"

local Breakable = std.Mechanic {}
export type BreakableMechanic = std.Mechanic<typeof(Breakable)>
Breakable.name = "Breakable"
Breakable.instanceType = std.isA.Instance()
Breakable.emoji = "💥"

return Breakable
